import EthereumKit
import Erc20Kit
import BigInt

class OneInchTransactionDecorator {
    private static let ethTokenAddresses = ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", "0x0000000000000000000000000000000000000000"]

    private let address: Address

    init(address: Address) {
        self.address = address
    }

    private func totalTokenIncoming(userAddress: Address, tokenAddress: Address, eventInstances: [ContractEventInstance]) -> BigUInt {
        var amount: BigUInt = 0

        for eventInstance in eventInstances {
            if eventInstance.contractAddress == tokenAddress, let transferEventInstance = eventInstance as? TransferEventInstance,
               transferEventInstance.to == userAddress, transferEventInstance.value > 0 {
                amount += transferEventInstance.value
            }
        }

        return amount
    }

    private func totalEthIncoming(userAddress: Address, internalTransactions: [InternalTransaction]) -> BigUInt {
        var amount: BigUInt = 0

        for internalTransaction in internalTransactions {
            if internalTransaction.to == userAddress {
                amount += internalTransaction.value
            }
        }

        return amount
    }

    private func addressToToken(address: Address) -> OneInchDecoration.Token {
        let eip55Address = address.eip55

        if OneInchTransactionDecorator.ethTokenAddresses.contains(eip55Address) {
            return .evmCoin
        } else {
            return .eip20Coin(address: address)
        }
    }

}

extension OneInchTransactionDecorator: ITransactionDecorator {

    public func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration? {
        guard let from = from, let to = to, let value = value, let contractMethod = contractMethod else {
            return nil
        }

        switch contractMethod {
        case let method as SwapMethod:
            let swapDescription = method.swapDescription
            let tokenOut = addressToToken(address: swapDescription.dstToken)

            var amountOut: OneInchDecoration.Amount = .extremum(value: swapDescription.minReturnAmount)

            switch tokenOut {
            case .evmCoin:
                if !internalTransactions.isEmpty {
                    amountOut = .exact(value: totalEthIncoming(userAddress: swapDescription.dstReceiver, internalTransactions: internalTransactions))
                }
            case .eip20Coin:
                if !eventInstances.isEmpty {
                    amountOut = .exact(value: totalTokenIncoming(userAddress: swapDescription.dstReceiver, tokenAddress: swapDescription.dstToken, eventInstances: eventInstances))
                }
            }

            return OneInchSwapDecoration(
                    contractAddress: to,
                    tokenIn: addressToToken(address: swapDescription.srcToken),
                    tokenOut: tokenOut,
                    amountIn: swapDescription.amount,
                    amountOut: amountOut,
                    flags: swapDescription.flags,
                    permit: swapDescription.permit,
                    data: method.data,
                    recipient: swapDescription.dstReceiver == from ? nil : swapDescription.dstReceiver
            )

        case let method as UnoswapMethod:
            var tokenOut: OneInchDecoration.Token?
            var amountOut: OneInchDecoration.Amount = .extremum(value: method.minReturn)

            if !internalTransactions.isEmpty {
                let amount = totalEthIncoming(userAddress: address, internalTransactions: internalTransactions)

                if amount > 0 {
                    tokenOut = .evmCoin
                    amountOut = .exact(value: amount)
                }
            }

            if tokenOut == nil, !eventInstances.isEmpty {
                let incomingEip20EventInstance = eventInstances.first { eventInstance in
                    if let transferEventInstance = eventInstance as? TransferEventInstance {
                        return transferEventInstance.to == address
                    }

                    return false
                }

                if let eventInstance = incomingEip20EventInstance {
                    let amount = totalTokenIncoming(userAddress: address, tokenAddress: eventInstance.contractAddress, eventInstances: eventInstances)

                    if amount > 0 {
                        tokenOut = .eip20Coin(address: eventInstance.contractAddress)
                        amountOut = .exact(value: amount)
                    }
                }
            }

            return OneInchUnoswapDecoration(
                    contractAddress: to,
                    tokenIn: addressToToken(address: method.srcToken),
                    tokenOut: tokenOut,
                    amountIn: method.amount,
                    amountOut: amountOut,
                    params: method.params
            )

        case is OneInchV4Method:
            return OneInchDecoration(contractAddress: to)

        default: return nil
        }
    }

}

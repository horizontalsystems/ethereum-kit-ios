import EthereumKit
import Erc20Kit
import BigInt

class OneInchTransactionDecorator {
    private static let ethTokenAddresses = ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", "0x0000000000000000000000000000000000000000"]

    private let address: Address
    private let contractMethodFactories: OneInchContractMethodFactories

    init(address: Address, contractMethodFactories: OneInchContractMethodFactories) {
        self.address = address
        self.contractMethodFactories = contractMethodFactories
    }

    private func totalTokenIncoming(userAddress: Address, tokenAddress: Address, eventDecorations: [ContractEventDecoration]) -> BigUInt? {
        var amountOut: BigUInt = 0

        for decoration in eventDecorations {
            if decoration.contractAddress == tokenAddress,
               let transferEventDecoration = decoration as? TransferEventDecoration,
               transferEventDecoration.to == userAddress, transferEventDecoration.value > 0 {
                amountOut += transferEventDecoration.value
            }
        }

        return amountOut > 0 ? amountOut : nil
    }

    private func totalETHIncoming(userAddress: Address, transactions: [InternalTransaction]) -> BigUInt? {
        var amountOut: BigUInt = 0

        for transaction in transactions {
            if transaction.to == userAddress {
                amountOut += transaction.value
            }
        }

        return amountOut > 0 ? amountOut : nil
    }

    private func addressToToken(address: Address) -> OneInchMethodDecoration.Token {
        let eip55Address = address.eip55

        if OneInchTransactionDecorator.ethTokenAddresses.contains(eip55Address) {
            return .evmCoin
        } else {
            return .eip20Coin(address: address)
        }
    }

    private func methodDecoration(transactionData: TransactionData, internalTransactions: [InternalTransaction]? = nil, eventDecorations: [ContractEventDecoration]? = nil) -> ContractMethodDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        switch contractMethod {
        case let method as UnoswapMethod:
            var tokenOut: OneInchMethodDecoration.Token? = nil
            var amountOut: BigUInt? = nil

            if let internalTransactions = internalTransactions,
               let amount = totalETHIncoming(userAddress: address, transactions: internalTransactions) {
                amountOut = amount
                tokenOut = .evmCoin
            }

            if tokenOut == nil, let eventDecorations = eventDecorations {
                let incomingEip20EventDecoration = eventDecorations.first(where: { eventDecoration in
                    if let transferEventDecoration = eventDecoration as? TransferEventDecoration {
                        return transferEventDecoration.to == address
                    }

                    return false
                })

                if let decoration = incomingEip20EventDecoration,
                   let amount = totalTokenIncoming(userAddress: address, tokenAddress: decoration.contractAddress, eventDecorations: eventDecorations) {
                    amountOut = amount
                    tokenOut = .eip20Coin(address: decoration.contractAddress)
                }
            }

            return OneInchUnoswapMethodDecoration(
                    tokenIn: addressToToken(address: method.srcToken),
                    tokenOut: tokenOut,
                    amountIn: method.amount,
                    amountOutMin: method.minReturn,
                    amountOut: amountOut,
                    params: method.params
            )

        case let method as SwapMethod:
            var amountOut: BigUInt? = nil
            let swapDescription = method.swapDescription
            let tokenOut = addressToToken(address: swapDescription.dstToken)

            if let internalTransactions = internalTransactions,
               case .evmCoin = tokenOut,
               let amount = totalETHIncoming(userAddress: swapDescription.dstReceiver, transactions: internalTransactions) {
                amountOut = amount
            }

            if amountOut == nil, let eventDecorations = eventDecorations,
               let amount = totalTokenIncoming(userAddress: swapDescription.dstReceiver, tokenAddress: swapDescription.dstToken, eventDecorations: eventDecorations){
                amountOut = amount
            }

            return OneInchSwapMethodDecoration(
                    tokenIn: addressToToken(address: swapDescription.srcToken),
                    tokenOut: tokenOut,
                    amountIn: swapDescription.amount,
                    amountOutMin: swapDescription.minReturnAmount,
                    amountOut: amountOut,
                    flags: swapDescription.flags,
                    permit: swapDescription.permit,
                    data: method.data,
                    recipient: swapDescription.dstReceiver
            )

        case is OneInchV4Method:
            return OneInchMethodDecoration()

        default: return nil
        }
    }

    private func decorateMain(fullTransaction: FullTransaction, eventDecorations: [ContractEventDecoration]) {
        guard fullTransaction.transaction.from == address else {
            // We only parse transactions created by the user (owner of this wallet).
            // If a swap was initiated by someone else and "recipient" is set to user's it should be shown as just an incoming transaction
            return
        }

        guard let transactionData = fullTransaction.transactionData else {
            return
        }

        guard let decoration = methodDecoration(transactionData: transactionData, internalTransactions: fullTransaction.internalTransactions, eventDecorations: eventDecorations) else {
            return
        }

        fullTransaction.mainDecoration = decoration
    }

}

extension OneInchTransactionDecorator: IDecorator {

    public func decorate(transactionData: TransactionData) -> ContractMethodDecoration? {
        methodDecoration(transactionData: transactionData)
    }

    public func decorate(fullTransaction: FullTransaction, fullRpcTransaction: FullRpcTransaction) {
        decorateMain(fullTransaction: fullTransaction, eventDecorations: fullRpcTransaction.rpcTransactionReceipt.logs.compactMap { $0.erc20EventDecoration() })
    }

    public func decorate(fullTransactionMap: [Data: FullTransaction]) {
        for fullTransaction in fullTransactionMap.values {
            decorateMain(fullTransaction: fullTransaction, eventDecorations: fullTransaction.eventDecorations)
        }
    }

}

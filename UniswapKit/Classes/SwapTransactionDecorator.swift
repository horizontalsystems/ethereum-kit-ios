import EthereumKit
import Erc20Kit
import BigInt

class SwapTransactionDecorator {

    private func totalTokenAmount(userAddress: Address, tokenAddress: Address, eventInstances: [ContractEventInstance], collectIncomingAmounts: Bool) -> BigUInt {
        var amountIn: BigUInt = 0
        var amountOut: BigUInt = 0

        for eventInstance in eventInstances {
            if eventInstance.contractAddress == tokenAddress, let transferEventInstance = eventInstance as? TransferEventInstance {
                if transferEventInstance.from == userAddress {
                    amountIn += transferEventInstance.value
                }

                if transferEventInstance.to == userAddress {
                    amountOut += transferEventInstance.value
                }
            }
        }

        return collectIncomingAmounts ? amountIn : amountOut
    }

    private func totalETHIncoming(userAddress: Address, internalTransactions: [InternalTransaction]) -> BigUInt {
        var amount: BigUInt = 0

        for internalTransaction in internalTransactions {
            if internalTransaction.to == userAddress {
                amount += internalTransaction.value
            }
        }

        return amount
    }

    private func eip20Token(address: Address, eventInstances: [ContractEventInstance]) -> SwapDecoration.Token {
        .eip20Coin(
                address: address,
                tokenInfo: eventInstances.compactMap { $0 as? TransferEventInstance }.first { $0.contractAddress == address }?.tokenInfo
        )
    }

}

extension SwapTransactionDecorator: ITransactionDecorator {

    public func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration? {
        guard let from = from, let to = to, let value = value, let contractMethod = contractMethod else {
            return nil
        }

        switch contractMethod {
        case let method as SwapETHForExactTokensMethod:
            guard let lastCoinInPath = method.path.last else {
                return nil
            }

            let amountIn: SwapDecoration.Amount

            if internalTransactions.isEmpty {
                amountIn = .extremum(value: value)
            } else {
                let change = totalETHIncoming(userAddress: method.to, internalTransactions: internalTransactions)
                amountIn = .exact(value: value - change)
            }

            return SwapDecoration(
                    contractAddress: to,
                    amountIn: amountIn,
                    amountOut: .exact(value: method.amountOut),
                    tokenIn: .evmCoin,
                    tokenOut: eip20Token(address: lastCoinInPath, eventInstances: eventInstances),
                    recipient: method.to == from ? nil : method.to,
                    deadline: method.deadline
            )

        case let method as SwapExactETHForTokensMethod:
            guard let lastCoinInPath = method.path.last else {
                return nil
            }

            let totalAmount = totalTokenAmount(userAddress: method.to, tokenAddress: lastCoinInPath, eventInstances: eventInstances, collectIncomingAmounts: false)
            let amountOut: SwapDecoration.Amount = totalAmount != 0 ? .exact(value: totalAmount) : .extremum(value: method.amountOutMin)

            return SwapDecoration(
                    contractAddress: to,
                    amountIn: .exact(value: value),
                    amountOut: amountOut,
                    tokenIn: .evmCoin,
                    tokenOut: eip20Token(address: lastCoinInPath, eventInstances: eventInstances),
                    recipient: method.to == from ? nil : method.to,
                    deadline: method.deadline
            )

        case let method as SwapExactTokensForETHMethod:
            guard let firstCoinInPath = method.path.first else {
                return nil
            }

            let amountOut: SwapDecoration.Amount

            if internalTransactions.isEmpty {
                amountOut = .extremum(value: method.amountOutMin)
            } else {
                amountOut = .exact(value: totalETHIncoming(userAddress: method.to, internalTransactions: internalTransactions))
            }

            return SwapDecoration(
                    contractAddress: to,
                    amountIn: .exact(value: method.amountIn),
                    amountOut: amountOut,
                    tokenIn: eip20Token(address: firstCoinInPath, eventInstances: eventInstances),
                    tokenOut: .evmCoin,
                    recipient: method.to == from ? nil : method.to,
                    deadline: method.deadline
            )

        case let method as SwapExactTokensForTokensMethod:
            guard let firstCoinInPath = method.path.first, let lastCoinInPath = method.path.last else {
                return nil
            }

            let totalAmount = totalTokenAmount(userAddress: method.to, tokenAddress: lastCoinInPath, eventInstances: eventInstances, collectIncomingAmounts: false)
            let amountOut: SwapDecoration.Amount = totalAmount != 0 ? .exact(value: totalAmount) : .extremum(value: method.amountOutMin)

            return SwapDecoration(
                    contractAddress: to,
                    amountIn: .exact(value: method.amountIn),
                    amountOut: amountOut,
                    tokenIn: eip20Token(address: firstCoinInPath, eventInstances: eventInstances),
                    tokenOut: eip20Token(address: lastCoinInPath, eventInstances: eventInstances),
                    recipient: method.to == from ? nil : method.to,
                    deadline: method.deadline
            )

        case let method as SwapTokensForExactETHMethod:
            guard let firstCoinInPath = method.path.first else {
                return nil
            }

            let totalAmount = totalTokenAmount(userAddress: method.to, tokenAddress: firstCoinInPath, eventInstances: eventInstances, collectIncomingAmounts: true)
            let amountIn: SwapDecoration.Amount = totalAmount != 0 ? .exact(value: totalAmount) : .extremum(value: method.amountInMax)

            return SwapDecoration(
                    contractAddress: to,
                    amountIn: amountIn,
                    amountOut: .exact(value: method.amountOut),
                    tokenIn: eip20Token(address: firstCoinInPath, eventInstances: eventInstances),
                    tokenOut: .evmCoin,
                    recipient: method.to == from ? nil : method.to,
                    deadline: method.deadline
            )

        case let method as SwapTokensForExactTokensMethod:
            guard let firstCoinInPath = method.path.first, let lastCoinInPath = method.path.last else {
                return nil
            }

            let totalAmount = totalTokenAmount(userAddress: method.to, tokenAddress: firstCoinInPath, eventInstances: eventInstances, collectIncomingAmounts: true)
            let amountIn: SwapDecoration.Amount = totalAmount != 0 ? .exact(value: totalAmount) : .extremum(value: method.amountInMax)

            return SwapDecoration(
                    contractAddress: to,
                    amountIn: amountIn,
                    amountOut: .exact(value: method.amountOut),
                    tokenIn: eip20Token(address: firstCoinInPath, eventInstances: eventInstances),
                    tokenOut: eip20Token(address: lastCoinInPath, eventInstances: eventInstances),
                    recipient: method.to == from ? nil : method.to,
                    deadline: method.deadline
            )

        default: ()
        }

        return nil
    }

}

import EthereumKit

class SwapTransactionDecorator {
    private let contractMethodFactories: SwapContractMethodFactories

    init(contractMethodFactories: SwapContractMethodFactories) {
        self.contractMethodFactories = contractMethodFactories
    }

}

extension SwapTransactionDecorator: IDecorator {

    func decorate(transactionData: TransactionData) -> TransactionDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        switch contractMethod {
        case let method as SwapETHForExactTokensMethod:
            guard let lastCoinInPath = method.path.last else {
                return nil
            }

            return .swap(
                    trade: .exactOut(amountOut: method.amountOut, amountInMax: transactionData.value),
                    tokenIn: .evmCoin,
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )

        case let method as SwapExactETHForTokensMethod:
            guard let lastCoinInPath = method.path.last else {
                return nil
            }

            return .swap(
                    trade: .exactIn(amountIn: transactionData.value, amountOutMin: method.amountOutMin),
                    tokenIn: .evmCoin,
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )

        case let method as SwapExactTokensForETHMethod:
            guard let firstCoinInPath = method.path.first else {
                return nil
            }

            return .swap(
                    trade: .exactIn(amountIn: method.amountIn, amountOutMin: method.amountOutMin),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .evmCoin,
                    to: method.to,
                    deadline: method.deadline
            )

        case let method as SwapExactTokensForTokensMethod:
            guard let firstCoinInPath = method.path.first, let lastCoinInPath = method.path.last else {
                return nil
            }

            return .swap(
                    trade: .exactIn(amountIn: method.amountIn, amountOutMin: method.amountOutMin),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )

        case let method as SwapTokensForExactETHMethod:
            guard let firstCoinInPath = method.path.first else {
                return nil
            }

            return .swap(
                    trade: .exactOut(amountOut: method.amountOut, amountInMax: method.amountInMax),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .evmCoin,
                    to: method.to,
                    deadline: method.deadline
            )

        case let method as SwapTokensForExactTokensMethod:
            guard let firstCoinInPath = method.path.first, let lastCoinInPath = method.path.last else {
                return nil
            }

            return .swap(
                    trade: .exactOut(amountOut: method.amountOut, amountInMax: method.amountInMax),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )

        default: return nil
        }
    }

}

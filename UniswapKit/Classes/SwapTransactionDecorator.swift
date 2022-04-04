import EthereumKit
import Erc20Kit
import BigInt

class SwapTransactionDecorator {
    private let address: Address
    private let contractMethodFactories: SwapContractMethodFactories

    init(address: Address, contractMethodFactories: SwapContractMethodFactories) {
        self.address = address
        self.contractMethodFactories = contractMethodFactories
    }

    private func totalTokenAmount(userAddress: Address, tokenAddress: Address, eventDecorations: [ContractEventDecoration], collectIncomingAmounts: Bool) -> BigUInt {
        var amountIn: BigUInt = 0
        var amountOut: BigUInt = 0

        for eventDecoration in eventDecorations {
            if eventDecoration.contractAddress == tokenAddress, let transferEventDecoration = eventDecoration as? TransferEventDecoration {
                if transferEventDecoration.from == userAddress {
                    amountIn += transferEventDecoration.value
                }

                if transferEventDecoration.to == userAddress {
                    amountOut += transferEventDecoration.value
                }
            }
        }

        return collectIncomingAmounts ? amountIn : amountOut
    }

    private func totalETHIncoming(userAddress: Address, transactions: [InternalTransaction]) -> BigUInt {
        var amountOut: BigUInt = 0

        for transaction in transactions {
            if transaction.to == userAddress {
                amountOut += transaction.value
            }
        }

        return amountOut
    }

    private func methodDecoration(transactionData: TransactionData, internalTransactions: [InternalTransaction]? = nil, eventDecorations: [ContractEventDecoration]? = nil) -> ContractMethodDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        switch contractMethod {
        case let method as SwapETHForExactTokensMethod:
            guard let lastCoinInPath = method.path.last else {
                return nil
            }

            var amountIn: BigUInt? = nil
            if let internalTransactions = internalTransactions {
                let change = totalETHIncoming(userAddress: method.to, transactions: internalTransactions)
                amountIn = transactionData.value - change
            }

            return SwapMethodDecoration(
                    trade: .exactOut(amountOut: method.amountOut, amountInMax: transactionData.value, amountIn: amountIn),
                    tokenIn: .evmCoin,
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )
//          3ff5e170e270c94f58e307857d41e8ebd7d078f25e6c8965344f0dbb6c0c62b8
//          exactOut(amountOut: 50000000000000000000, amountInMax: 5419440020395405, amountIn: Optional(5392477632234234)), tokenIn: evmCoin, tokenOut: eip20Coin(address: 0x101848d5c5bbca18e6b4431eedf6b95e9adf82fa), to: 0xda8086165e5b4fa1eb2ab27722339a6db8eb7fae, deadline: 1621926349)

        case let method as SwapExactETHForTokensMethod:
            guard let lastCoinInPath = method.path.last else {
                return nil
            }

            var amountOut: BigUInt? = nil
            if let eventDecorations = eventDecorations {
                amountOut = totalTokenAmount(userAddress: method.to, tokenAddress: lastCoinInPath, eventDecorations: eventDecorations, collectIncomingAmounts: false)
            }

            return SwapMethodDecoration(
                    trade: .exactIn(amountIn: transactionData.value, amountOutMin: method.amountOutMin, amountOut: amountOut),
                    tokenIn: .evmCoin,
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )
//          ea8f9962b56fb34e81657b34456668f873896be25b7fd6811406225e528403c5
//          exactIn(amountIn: 10000000000000000, amountOutMin: 730611499602306243853, amountOut: Optional(734264557100317775073)), tokenIn: evmCoin, tokenOut: eip20Coin(address: 0x101848d5c5bbca18e6b4431eedf6b95e9adf82fa), to: 0xda8086165e5b4fa1eb2ab27722339a6db8eb7fae, deadline: 1616490997)

        case let method as SwapExactTokensForETHMethod:
            guard let firstCoinInPath = method.path.first else {
                return nil
            }

            var amountOut: BigUInt? = nil
            if let internalTransactions = internalTransactions {
                amountOut = totalETHIncoming(userAddress: method.to, transactions: internalTransactions)
            }

            return SwapMethodDecoration(
                    trade: .exactIn(amountIn: method.amountIn, amountOutMin: method.amountOutMin, amountOut: amountOut),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .evmCoin,
                    to: method.to,
                    deadline: method.deadline
            )
//          669ca8f254aae34808b35d8f72a72eb3bfb4c5d8ed4ddf13725d715560055bae
//          exactIn(amountIn: 2000000000000000000, amountOutMin: 30347404218793086, amountOut: Optional(30499141239887052)), tokenIn: eip20Coin(address: 0xad6d458402f60fd3bd25163575031acdce07538d), tokenOut: evmCoin, to: 0xda8086165e5b4fa1eb2ab27722339a6db8eb7fae, deadline: 1621423254)

        case let method as SwapExactTokensForTokensMethod:
            guard let firstCoinInPath = method.path.first, let lastCoinInPath = method.path.last else {
                return nil
            }

            var amountOut: BigUInt? = nil
            if let eventDecorations = eventDecorations {
                amountOut = totalTokenAmount(userAddress: method.to, tokenAddress: lastCoinInPath, eventDecorations: eventDecorations, collectIncomingAmounts: false)
            }

            return SwapMethodDecoration(
                    trade: .exactIn(amountIn: method.amountIn, amountOutMin: method.amountOutMin, amountOut: amountOut),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )
//          5c63484eb0006697e59c62b4d187721efbc097b4515a3971767397f8f0b994a6
//          exactIn(amountIn: 100000000000000000000, amountOutMin: 724488982381145247, amountOut: Optional(728111427293050974)), tokenIn: eip20Coin(address: 0x101848d5c5bbca18e6b4431eedf6b95e9adf82fa), tokenOut: eip20Coin(address: 0xad6d458402f60fd3bd25163575031acdce07538d), to: 0xda8086165e5b4fa1eb2ab27722339a6db8eb7fae, deadline: 1621423423)

        case let method as SwapTokensForExactETHMethod:
            guard let firstCoinInPath = method.path.first else {
                return nil
            }

            var amountIn: BigUInt? = nil
            if let eventDecorations = eventDecorations {
                amountIn = totalTokenAmount(userAddress: method.to, tokenAddress: firstCoinInPath, eventDecorations: eventDecorations, collectIncomingAmounts: true)
            }

            return SwapMethodDecoration(
                    trade: .exactOut(amountOut: method.amountOut, amountInMax: method.amountInMax, amountIn: amountIn),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .evmCoin,
                    to: method.to,
                    deadline: method.deadline
            )
//          2e3e316e86211adcd55b5ecd32b7f817a36e33a820c49bd573bf83f8f9b96195 0
//          exactOut(amountOut: 20000000000000000, amountInMax: 183195634466095495490, amountIn: Optional(182284213399099995513)), tokenIn: eip20Coin(address: 0x101848d5c5bbca18e6b4431eedf6b95e9adf82fa), tokenOut: evmCoin, to: 0xda8086165e5b4fa1eb2ab27722339a6db8eb7fae, deadline: 1621925802)

        case let method as SwapTokensForExactTokensMethod:
            guard let firstCoinInPath = method.path.first, let lastCoinInPath = method.path.last else {
                return nil
            }

            var amountIn: BigUInt? = nil
            if let eventDecorations = eventDecorations {
                amountIn = totalTokenAmount(userAddress: method.to, tokenAddress: firstCoinInPath, eventDecorations: eventDecorations, collectIncomingAmounts: true)
            }

            return SwapMethodDecoration(
                    trade: .exactOut(amountOut: method.amountOut, amountInMax: method.amountInMax, amountIn: amountIn),
                    tokenIn: .eip20Coin(address: firstCoinInPath),
                    tokenOut: .eip20Coin(address: lastCoinInPath),
                    to: method.to,
                    deadline: method.deadline
            )
//          71df63502014e85c2e8237d6f642ab651d12b3a1b5b8f57b91d5a13607d0b278
//          exactOut(amountOut: 10000000000000000000, amountInMax: 62192169434897117, amountIn: Optional(61636710041690673)), tokenIn: eip20Coin(address: 0xad6d458402f60fd3bd25163575031acdce07538d), tokenOut: eip20Coin(address: 0x101848d5c5bbca18e6b4431eedf6b95e9adf82fa), to: 0xda8086165e5b4fa1eb2ab27722339a6db8eb7fae, deadline: 1621932961)

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

extension SwapTransactionDecorator: IDecorator {

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

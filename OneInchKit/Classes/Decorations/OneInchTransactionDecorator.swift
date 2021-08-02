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

    private func totalTokenIncoming(userAddress: Address, tokenAddress: Address, logs: [TransactionLog]) -> BigUInt? {
        var amountOut: BigUInt = 0

        for log in logs {
            if log.address == tokenAddress,
               let erc20Event = log.erc20Event(),
               let transferEventDecoration = erc20Event as? TransferEventDecoration,
               transferEventDecoration.to == userAddress, transferEventDecoration.value > 0 {
                amountOut += transferEventDecoration.value
                log.set(relevant: true)
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

}

extension OneInchTransactionDecorator: IDecorator {

    func decorate(transactionData: TransactionData, fullTransaction: FullTransaction?) -> ContractMethodDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        if let transaction = fullTransaction?.transaction, transaction.from != address {
            // We only parse transactions created by the user (owner of this wallet).
            // If a swap was initiated by someone else and "recipient" is set to user's it should be shown as just an incoming transaction
            return nil
        }

        switch contractMethod {
        case let method as UnoswapMethod:
            var tokenOut: OneInchMethodDecoration.Token? = nil
            var amountOut: BigUInt? = nil

            if let fullTransaction = fullTransaction,
               let amount = totalETHIncoming(userAddress: address, transactions: fullTransaction.internalTransactions) {
                amountOut = amount
                tokenOut = .evmCoin
            }

            if tokenOut == nil, let logs = fullTransaction?.receiptWithLogs?.logs {
                let incomingEip20Log = logs.first(where: { log in
                    if let erc20Event = log.erc20Event(), let transferEventDecoration = erc20Event as? TransferEventDecoration {
                        return transferEventDecoration.to == address
                    }

                    return false
                })

                if let incomingEip20Log = incomingEip20Log,
                   let erc20Event = incomingEip20Log.erc20Event(), let transferEventDecoration = erc20Event as? TransferEventDecoration,
                   let amount = totalTokenIncoming(userAddress: address, tokenAddress: transferEventDecoration.contractAddress, logs: logs) {
                    amountOut = amount
                    tokenOut = .eip20Coin(address: transferEventDecoration.contractAddress)
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

            if let fullTransaction = fullTransaction,
               case .evmCoin = tokenOut,
               let amount = totalETHIncoming(userAddress: swapDescription.dstReceiver, transactions: fullTransaction.internalTransactions) {
                amountOut = amount
            }

            if amountOut == nil, let logs = fullTransaction?.receiptWithLogs?.logs,
               let amount = totalTokenIncoming(userAddress: swapDescription.dstReceiver, tokenAddress: swapDescription.dstToken, logs: logs){
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

        default: return nil
        }
    }

    public func decorate(logs: [TransactionLog]) -> [ContractEventDecoration] {
        []
    }

}

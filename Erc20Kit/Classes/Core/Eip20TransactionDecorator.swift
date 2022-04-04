import EthereumKit

class Eip20TransactionDecorator {
    private let userAddress: Address
    private let contractMethodFactories: ContractMethodFactories
    private let evmKit: EthereumKit.Kit

    init(userAddress: Address, contractMethodFactories: ContractMethodFactories, evmKit: EthereumKit.Kit) {
        self.userAddress = userAddress
        self.contractMethodFactories = contractMethodFactories
        self.evmKit = evmKit
    }

    private func decorateMain(fullTransaction: FullTransaction) {
        guard let transactionData = fullTransaction.transactionData else {
            return
        }

        guard let decoration = decorate(transactionData: transactionData) else {
            return
        }

        fullTransaction.mainDecoration = decoration
    }

    private func decorateEvents(fullTransactionMap: [Data: FullTransaction]) {
        let events: [Event]

        if fullTransactionMap.count > 100 {
            events = evmKit.events()
        } else {
            let hashes = fullTransactionMap.values.map { $0.transaction.hash }
            events = evmKit.events(hashes: hashes)
        }

        for event in events {
            fullTransactionMap[event.hash]?.eventDecorations.append(
                    TransferEventDecoration(
                            contractAddress: event.contractAddress,
                            from: event.from,
                            to: event.to,
                            value: event.value,
                            tokenName: event.tokenName,
                            tokenSymbol: event.tokenSymbol,
                            tokenDecimal: event.tokenDecimal
                    )
            )
        }
    }

    private func decorateLogs(fullTransaction: FullTransaction, logs: [TransactionLog]) {
        let eventDecorations = logs.compactMap { log -> ContractEventDecoration? in
            guard let event = log.erc20EventDecoration() else {
                return nil
            }

            switch event {
            case let transfer as TransferEventDecoration:
                if transfer.from == userAddress || transfer.to == userAddress {
                    return event
                }

            case let approve as ApproveEventDecoration:
                if approve.owner == userAddress || approve.spender == userAddress {
                    return event
                }

            default: ()
            }

            return nil
        }

        fullTransaction.eventDecorations.append(contentsOf: eventDecorations)
    }

}

extension Eip20TransactionDecorator: IDecorator {

    public func decorate(transactionData: TransactionData) -> ContractMethodDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        switch contractMethod {
        case let transferMethod as TransferMethod: return TransferMethodDecoration(to: transferMethod.to, value: transferMethod.value)
        case let approveMethod as ApproveMethod: return ApproveMethodDecoration(spender: approveMethod.spender, value: approveMethod.value)
        default: return nil
        }
    }

    public func decorate(fullTransaction: FullTransaction, fullRpcTransaction: FullRpcTransaction) {
        decorateMain(fullTransaction: fullTransaction)
        decorateLogs(fullTransaction: fullTransaction, logs: fullRpcTransaction.rpcTransactionReceipt.logs)
    }

    public func decorate(fullTransactionMap: [Data: FullTransaction]) {
        for fullTransaction in fullTransactionMap.values {
            decorateMain(fullTransaction: fullTransaction)
        }

        decorateEvents(fullTransactionMap: fullTransactionMap)
    }

}

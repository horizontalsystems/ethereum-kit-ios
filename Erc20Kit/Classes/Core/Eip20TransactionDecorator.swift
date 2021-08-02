import EthereumKit

class Eip20TransactionDecorator {
    let contractMethodFactories: ContractMethodFactories
    let userAddress: Address

    init(userAddress: Address, contractMethodFactories: ContractMethodFactories) {
        self.userAddress = userAddress
        self.contractMethodFactories = contractMethodFactories
    }

}

extension Eip20TransactionDecorator: IDecorator {

    public func decorate(transactionData: TransactionData, fullTransaction: FullTransaction?) -> ContractMethodDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        switch contractMethod {
        case let transferMethod as TransferMethod: return TransferMethodDecoration(to: transferMethod.to, value: transferMethod.value)
        case let approveMethod as ApproveMethod: return ApproveMethodDecoration(spender: approveMethod.spender, value: approveMethod.value)
        default: return nil
        }
    }

    public func decorate(logs: [TransactionLog]) -> [ContractEventDecoration] {
        logs.compactMap { log -> ContractEventDecoration? in
            guard let event = log.erc20Event() else {
                return nil
            }

            switch event {
            case let transfer as TransferEventDecoration:
                if transfer.from == userAddress || transfer.to == userAddress {
                    log.set(relevant: true)
                    return event
                }

            case let approve as ApproveEventDecoration:
                if approve.owner == userAddress || approve.spender == userAddress {
                    log.set(relevant: true)
                    return event
                }

            default: ()
            }

            return nil
        }
    }

}

import EthereumKit

class Eip20TransactionDecorator {
    let contractMethodFactories: ContractMethodFactories
    let userAddress: Address
    let tokenAddress: Address

    init(userAddress: Address, tokenAddress: Address, contractMethodFactories: ContractMethodFactories) {
        self.userAddress = userAddress
        self.tokenAddress = tokenAddress
        self.contractMethodFactories = contractMethodFactories
    }

}

extension Eip20TransactionDecorator: IDecorator {

    public func decorate(transactionData: TransactionData, fullTransaction: FullTransaction?) -> TransactionDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        switch contractMethod {
        case let transferMethod as TransferMethod: return TransferTransactionDecoration(to: transferMethod.to, value: transferMethod.value)
        case let approveMethod as ApproveMethod: return ApproveTransactionDecoration(spender: approveMethod.spender, value: approveMethod.value)
        default: return nil
        }
    }

    public func decorate(logs: [TransactionLog]) -> [EventDecoration] {
        logs.compactMap { log -> EventDecoration? in
            guard log.address == tokenAddress, let event = log.erc20Event() else {
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
    }

}

import EthereumKit

class Eip20TransactionDecorator {
    let contractMethodFactories: ContractMethodFactories

    init(contractMethodFactories: ContractMethodFactories) {
        self.contractMethodFactories = contractMethodFactories
    }

}

extension Eip20TransactionDecorator: IDecorator {

    public func decorate(transactionData: TransactionData) -> TransactionDecoration? {
        guard let contractMethod = contractMethodFactories.createMethod(input: transactionData.input) else {
            return nil
        }

        switch contractMethod {
        case let transferMethod as TransferMethod: return .eip20Transfer(to: transferMethod.to, value: transferMethod.value, contractAddress: transactionData.to)
        case let approveMethod as ApproveMethod: return .eip20Approve(spender: approveMethod.spender, value: approveMethod.value, contractAddress: transactionData.to)
        default: return nil
        }
    }

}

import BigInt
import Foundation

class ContractCallDecorator: IDecorator {

    private class RecognizedContractMethod {
        let name: String
        let signature: String
        let arguments: [Any]
        let methodId: Data

        init(name: String, signature: String, arguments: [Any]) {
            self.name = name
            self.signature = signature
            self.arguments = arguments
            methodId = ContractMethodHelper.methodId(signature: signature)
        }
    }

    private var address: Address
    private var methods = [Data: RecognizedContractMethod]()

    init(address: Address) {
        self.address = address

        addMethod(name: "Deposit", signature: "deposit(uint256)", arguments: [BigUInt.self])
        addMethod(name: "TradeWithHintAndFee", signature: "tradeWithHintAndFee(address,uint256,address,address,uint256,uint256,address,uint256,bytes)",
                arguments: [Address.self, BigUInt.self, Address.self, Address.self, BigUInt.self, BigUInt.self, Address.self, BigUInt.self, Data.self])
    }

    private func addMethod(name: String, signature: String, arguments: [Any]) {
        let method = RecognizedContractMethod(name: name, signature: signature, arguments: arguments)
        methods[method.methodId] = method
    }

    func decorate(transactionData: TransactionData, fullTransaction: FullTransaction?) -> ContractMethodDecoration? {
        guard let transaction = fullTransaction?.transaction, transaction.from == address else {
            return nil
        }

        let methodId = Data(transactionData.input.prefix(4))
        let inputArguments = Data(transactionData.input.suffix(from: 4))

        guard let method = methods[methodId] else {
            return nil
        }

        let arguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: method.arguments)

        return RecognizedMethodDecoration(method: method.name, arguments: arguments)
    }

    func decorate(logs: [TransactionLog]) -> [ContractEventDecoration] {
        []
    }

}

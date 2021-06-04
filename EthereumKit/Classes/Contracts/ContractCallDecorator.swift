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

    private var methods = [Data: RecognizedContractMethod]()

    init() {
        addMethod(name: "deposit", signature: "deposit(uint256)", arguments: [BigUInt.self])
        addMethod(name: "tradeWithHintAndFee", signature: "tradeWithHintAndFee(address,uint256,address,address,uint256,uint256,address,uint256,bytes)",
                arguments: [Address.self, BigUInt.self, Address.self, Address.self, BigUInt.self, BigUInt.self, Address.self, BigUInt.self, Data.self])
    }

    private func addMethod(name: String, signature: String, arguments: [Any]) {
        let method = RecognizedContractMethod(name: name, signature: signature, arguments: arguments)
        methods[method.methodId] = method
    }

    func decorate(transactionData: TransactionData, fullTransaction: FullTransaction?) -> TransactionDecoration? {
        let methodId = Data(transactionData.input.prefix(4))
        let inputArguments = Data(transactionData.input.suffix(from: 4))

        guard let method = methods[methodId] else {
            return nil
        }

        let arguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: method.arguments)

        return .recognized(method: method.name, arguments: arguments)
    }

    func decorate(logs: [TransactionLog]) -> [EventDecoration] {
        []
    }

}

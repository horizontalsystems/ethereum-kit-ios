import BigInt

class TransactionDecorator: IDecorator {

    private class RecognizedContractMethod {
        let methodSignature: String
        let arguments: [Any]
        let methodId: Data

        init(methodSignature: String, arguments: [Any]) {
            self.methodSignature = methodSignature
            self.arguments = arguments
            methodId = ContractMethodHelper.methodId(signature: methodSignature)
        }
    }

    private var methods = [Data: RecognizedContractMethod]()

    init() {
        addMethod(methodSignature: "deposit(uint256)", arguments: [BigUInt.self])
    }

    private func addMethod(methodSignature: String, arguments: [Any]) {
        let method = RecognizedContractMethod(methodSignature: methodSignature, arguments: arguments)
        methods[method.methodId] = method
    }

    func decorate(transactionData: TransactionData, fullTransaction: FullTransaction?) -> TransactionDecoration? {
        let methodId = Data(transactionData.input.prefix(4))
        let inputArguments = Data(transactionData.input.suffix(from: 4))

        guard let method = methods[methodId] else {
            return nil
        }


        let arguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: method.arguments)

        return .recognized(method: method.methodSignature, arguments: arguments)
    }

    func decorate(logs: [TransactionLog]) -> [EventDecoration] {
        []
    }

}

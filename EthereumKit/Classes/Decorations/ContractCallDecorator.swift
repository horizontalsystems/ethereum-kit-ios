import BigInt
import Foundation

class ContractCallDecorator: IDecorator {

    private class RecognizedContractMethod {
        let name: String
        let signature: String?
        let arguments: [Any]?
        let methodId: Data

        init(name: String, signature: String, arguments: [Any]) {
            self.name = name
            self.signature = signature
            self.arguments = arguments
            methodId = ContractMethodHelper.methodId(signature: signature)
        }
        
        init(name: String, methodId: Data) {
            self.name = name
            self.methodId = methodId
            signature = nil
            arguments = nil
        }
    }

    private var address: Address
    private var methods = [Data: RecognizedContractMethod]()

    init(address: Address) {
        self.address = address

        addMethod(name: "Deposit", signature: "deposit(uint256)", arguments: [BigUInt.self])
        addMethod(name: "TradeWithHintAndFee", signature: "tradeWithHintAndFee(address,uint256,address,address,uint256,uint256,address,uint256,bytes)",
                arguments: [Address.self, BigUInt.self, Address.self, Address.self, BigUInt.self, BigUInt.self, Address.self, BigUInt.self, Data.self])
        
        addMethod(name: "Farm Deposit", methodId: "0xe2bbb158")
        addMethod(name: "Farm Withdrawal", methodId: "0x441a3e70")
        addMethod(name: "Pool Deposit", methodId: "0xf305d719")
        addMethod(name: "Pool Withdrawal", methodId: "0xded9382a")
        addMethod(name: "Stake", methodId: "0xa59f3e0c")
        addMethod(name: "Unstake", methodId: "0x67dfd4c9")
    }

    private func addMethod(name: String, signature: String, arguments: [Any]) {
        let method = RecognizedContractMethod(name: name, signature: signature, arguments: arguments)
        methods[method.methodId] = method
    }

    private func addMethod(name: String, methodId: String) {
        let method = RecognizedContractMethod(name: name, methodId: Data(hex: methodId)!)
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

        let arguments = method.arguments.flatMap {
            ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: $0)
        } ?? []

        return RecognizedMethodDecoration(method: method.name, arguments: arguments)
    }

    func decorate(logs: [TransactionLog]) -> [ContractEventDecoration] {
        []
    }

}

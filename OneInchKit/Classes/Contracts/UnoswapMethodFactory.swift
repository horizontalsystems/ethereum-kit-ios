import EthereumKit
import BigInt

class UnoswapMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: UnoswapMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: [Address.self, BigUInt.self, BigUInt.self, [Data].self])
        guard let srcToken = parsedArguments[0] as? Address,
              let amount = parsedArguments[1] as? BigUInt,
              let minReturn = parsedArguments[2] as? BigUInt,
              let params = parsedArguments[3] as? [Data] else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }

        return UnoswapMethod(srcToken: srcToken, amount: amount, minReturn: minReturn, params: params)
    }

}

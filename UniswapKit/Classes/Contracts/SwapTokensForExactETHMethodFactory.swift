import EthereumKit
import BigInt

class SwapTokensForExactETHMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: SwapTokensForExactETHMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: [BigUInt.self, BigUInt.self, [Address].self, Address.self, BigUInt.self])
        guard let amountOut = parsedArguments[0] as? BigUInt,
              let amountInMax = parsedArguments[1] as? BigUInt,
              let path = parsedArguments[2] as? [Address],
              let to = parsedArguments[3] as? Address,
              let deadline = parsedArguments[4] as? BigUInt else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }

        return SwapTokensForExactETHMethod(amountOut: amountOut, amountInMax: amountInMax, path: path, to: to, deadline: deadline)
    }

}

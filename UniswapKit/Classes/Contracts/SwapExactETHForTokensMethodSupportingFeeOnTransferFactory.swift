import EthereumKit
import BigInt

class SwapExactETHForTokensMethodSupportingFeeOnTransferFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: SwapExactETHForTokensMethod.methodSignature(supportingFeeOnTransfer: true))

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: [BigUInt.self, [Address].self, Address.self, BigUInt.self])
        guard let amountOut = parsedArguments[0] as? BigUInt,
              let path = parsedArguments[1] as? [Address],
              let to = parsedArguments[2] as? Address,
              let deadline = parsedArguments[3] as? BigUInt else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }

        return SwapExactETHForTokensMethod(amountOut: amountOut, path: path, to: to, deadline: deadline, supportingFeeOnTransfer: true)
    }

}

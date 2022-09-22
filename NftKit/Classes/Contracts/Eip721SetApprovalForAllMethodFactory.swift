import EthereumKit
import BigInt

class Eip721SetApprovalForAllMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: Eip721SetApprovalForAllMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        Eip721SetApprovalForAllMethod(
                operator: Address(raw: inputArguments[12..<32]),
                approved: BigUInt(inputArguments[32..<64]) != 0
        )
    }

}

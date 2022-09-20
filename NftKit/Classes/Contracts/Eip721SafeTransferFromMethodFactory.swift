import EthereumKit
import BigInt

class Eip721SafeTransferFromMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: Eip721SafeTransferFromMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        Eip721SafeTransferFromMethod(
                from: Address(raw: inputArguments[12..<32]),
                to: Address(raw: inputArguments[44..<64]),
                tokenId: BigUInt(inputArguments[64..<96]),
                data: inputArguments[96..<128]
        )
    }

}

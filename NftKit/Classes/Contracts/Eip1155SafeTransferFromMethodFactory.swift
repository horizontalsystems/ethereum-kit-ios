import EthereumKit
import BigInt

class Eip1155SafeTransferFromMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: Eip1155SafeTransferFromMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        Eip1155SafeTransferFromMethod(
                from: Address(raw: inputArguments[12..<32]),
                to: Address(raw: inputArguments[44..<64]),
                tokenId: BigUInt(inputArguments[64..<96]),
                value: BigUInt(inputArguments[96..<128]),
                data: inputArguments[128..<160]
        )
    }

}

import EthereumKit
import BigInt

class ApproveMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: "approve(address,uint256)")

    func createMethod(inputArguments: Data) -> ContractMethod {
        let spender = Address(raw: inputArguments[12..<32])
        let value = BigUInt(inputArguments[32..<64])

        return ApproveMethod(spender: spender, value: value)
    }

}

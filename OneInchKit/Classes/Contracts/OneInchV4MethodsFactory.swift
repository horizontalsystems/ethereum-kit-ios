import EthereumKit
import BigInt

class OneInchV4MethodsFactory: IContractMethodsFactory {
    var methodId: Data { Data() }
    let methodIds: [Data] = [
        ContractMethodHelper.methodId(signature: "fillOrderRFQ((uint256,address,address,address,address,uint256,uint256),bytes,uint256,uint256)"),
        ContractMethodHelper.methodId(signature: "fillOrderRFQTo((uint256,address,address,address,address,uint256,uint256),bytes,uint256,uint256,address)"),
        ContractMethodHelper.methodId(signature: "fillOrderRFQToWithPermit((uint256,address,address,address,address,uint256,uint256),bytes,uint256,uint256,address,bytes)"),
        ContractMethodHelper.methodId(signature: "clipperSwap(address,address,uint256,uint256)"),
        ContractMethodHelper.methodId(signature: "clipperSwapTo(address,address,address,uint256,uint256)"),
        ContractMethodHelper.methodId(signature: "clipperSwapToWithPermit(address,address,address,uint256,uint256,bytes)"),
        ContractMethodHelper.methodId(signature: "uniswapV3Swap(uint256,uint256,uint256[])"),
        ContractMethodHelper.methodId(signature: "uniswapV3SwapTo(address,uint256,uint256,uint256[])"),
        ContractMethodHelper.methodId(signature: "uniswapV3SwapToWithPermit(address,address,uint256,uint256,uint256[],bytes)"),
        ContractMethodHelper.methodId(signature: "unoswapWithPermit(address,uint256,uint256,bytes32[],bytes)")
    ]

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        OneInchV4Method()
    }

}

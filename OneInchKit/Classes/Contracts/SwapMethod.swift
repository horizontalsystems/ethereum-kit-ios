import EthereumKit
import BigInt

class SwapMethod: ContractMethod {
    static let methodSignature = "swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)"

    let caller: Address
    let swapDescription: SwapDescription
    let data: Data

    init(caller: Address, swapDescription: SwapDescription, data: Data) {
        self.caller = caller
        self.swapDescription = swapDescription
        self.data = data

        super.init()
    }

    override var methodSignature: String { SwapMethod.methodSignature }

    override var arguments: [Any] {
        [caller, swapDescription, data]
    }

    struct SwapDescription {
        let srcToken: Address
        let dstToken: Address
        let srcReceiver: Address
        let dstReceiver: Address
        let amount: BigUInt
        let minReturnAmount: BigUInt
        let flags: BigUInt
        let permit: Data
    }

}

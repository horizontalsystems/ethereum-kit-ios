import EthereumKit
import BigInt

// This method assumes that recipient is always the initiator of the transaction

class UnoswapMethod: ContractMethod {
    static let methodSignature = "unoswap(address,uint256,uint256,bytes32[])"

    let srcToken: Address
    let amount: BigUInt
    let minReturn: BigUInt
    let params: [Data]

    init(srcToken: Address, amount: BigUInt, minReturn: BigUInt, params: [Data]) {
        self.srcToken = srcToken
        self.amount = amount
        self.minReturn = minReturn
        self.params = params

        super.init()
    }

    override var methodSignature: String { UnoswapMethod.methodSignature }

    override var arguments: [Any] {
        [srcToken, amount, minReturn, params]
    }

}

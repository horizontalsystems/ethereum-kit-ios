import EthereumKit
import BigInt

class Eip721SafeTransferFromMethod: ContractMethod {
    static let methodSignature = "safeTransferFrom(address,address,uint256,bytes)"

    let from: Address
    let to: Address
    let tokenId: BigUInt
    let data: Data

    init(from: Address, to: Address, tokenId: BigUInt, data: Data) {
        self.from = from
        self.to = to
        self.tokenId = tokenId
        self.data = data

        super.init()
    }

    override var methodSignature: String { Self.methodSignature }
    override var arguments: [Any] { [from, to, tokenId, data] }
}

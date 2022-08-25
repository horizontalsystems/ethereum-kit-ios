import BigInt
import EthereumKit

class Eip721OwnerOfMethod: ContractMethod {
    private let tokenId: BigUInt

    init(tokenId: BigUInt) {
        self.tokenId = tokenId
    }

    override var methodSignature: String { "ownerOf(uint256)" }
    override var arguments: [Any] { [tokenId] }
}

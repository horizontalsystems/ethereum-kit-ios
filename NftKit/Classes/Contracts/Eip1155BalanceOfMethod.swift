import BigInt
import EthereumKit

class Eip1155BalanceOfMethod: ContractMethod {
    private let owner: Address
    private let tokenId: BigUInt

    init(owner: Address, tokenId: BigUInt) {
        self.owner = owner
        self.tokenId = tokenId
    }

    override var methodSignature: String { "balanceOf(address,uint256)" }
    override var arguments: [Any] { [owner, tokenId] }
}

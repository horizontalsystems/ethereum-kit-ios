import EthereumKit

class BalanceOfMethod: ContractMethod {
    private let owner: Address

    init(owner: Address) {
        self.owner = owner
    }

    override var methodSignature: String { "balanceOf(address)" }
    override var arguments: [Any] { [owner] }
}

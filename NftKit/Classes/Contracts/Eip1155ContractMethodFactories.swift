import EthereumKit

class Eip1155ContractMethodFactories: ContractMethodFactories {
    static let shared = Eip1155ContractMethodFactories()

    override init() {
        super.init()
        register(factories: [Eip1155SafeTransferFromMethodFactory()])
    }

}

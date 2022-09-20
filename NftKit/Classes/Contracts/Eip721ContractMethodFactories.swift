import EthereumKit

class Eip721ContractMethodFactories: ContractMethodFactories {
    static let shared = Eip721ContractMethodFactories()

    override init() {
        super.init()
        register(factories: [Eip721SafeTransferFromMethodFactory()])
    }

}

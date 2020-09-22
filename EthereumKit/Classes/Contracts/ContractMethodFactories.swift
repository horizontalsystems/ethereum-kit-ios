public class ContractMethodFactories {
    public static let shared = ContractMethodFactories()
    private var factories = [Data: IContractMethodFactory]()

    public func register(factory: IContractMethodFactory) {
        factories[factory.methodId] = factory
    }

    public func createMethod(input: Data) -> ContractMethod? {
        let methodId = Data(input.prefix(4))
        let erc20MethodFactory = factories[methodId]

        return erc20MethodFactory?.createMethod(inputArguments: Data(input.suffix(from: 4)))
    }
}



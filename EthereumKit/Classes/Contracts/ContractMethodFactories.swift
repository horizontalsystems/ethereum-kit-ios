open class ContractMethodFactories {
    public enum DecodeError: Error {
        case invalidABI
    }

    public init() {}

    private var factories = [Data: IContractMethodFactory]()

    public func register(factories: [IContractMethodFactory]) {
        for factory in factories {
            if let methodsFactory = factory as? IContractMethodsFactory {
                for methodId in methodsFactory.methodIds {
                    self.factories[methodId] = factory
                }
            } else {
                self.factories[factory.methodId] = factory
            }
        }
    }

    public func createMethod(input: Data) -> ContractMethod? {
        let methodId = Data(input.prefix(4))
        let erc20MethodFactory = factories[methodId]

        return try? erc20MethodFactory?.createMethod(inputArguments: Data(input.suffix(from: 4)))
    }

}

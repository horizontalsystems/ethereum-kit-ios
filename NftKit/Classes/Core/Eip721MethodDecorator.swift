import EthereumKit

class Eip721MethodDecorator {
    private let contractMethodFactories: ContractMethodFactories

    init(contractMethodFactories: ContractMethodFactories) {
        self.contractMethodFactories = contractMethodFactories
    }

}

extension Eip721MethodDecorator: IMethodDecorator {

    public func contractMethod(input: Data) -> ContractMethod? {
        contractMethodFactories.createMethod(input: input)
    }

}

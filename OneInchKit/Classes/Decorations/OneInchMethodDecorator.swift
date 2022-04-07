import EthereumKit

class OneInchMethodDecorator {
    private let contractMethodFactories: OneInchContractMethodFactories

    init(contractMethodFactories: OneInchContractMethodFactories) {
        self.contractMethodFactories = contractMethodFactories
    }

}

extension OneInchMethodDecorator: IMethodDecorator {

    public func contractMethod(input: Data) -> ContractMethod? {
        contractMethodFactories.createMethod(input: input)
    }

}

public protocol IContractMethodFactory {
    var methodId: Data { get }
    func createMethod(inputArguments: Data) throws -> ContractMethod
}

public protocol IContractMethodsFactory: IContractMethodFactory {
    var methodIds: [Data] { get }
}

extension IContractMethodsFactory {
    var methodId: Data { Data() }
}

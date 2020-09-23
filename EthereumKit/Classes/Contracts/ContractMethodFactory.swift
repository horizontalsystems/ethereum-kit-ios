public protocol IContractMethodFactory {
    var methodId: Data { get }
    func createMethod(inputArguments: Data) -> ContractMethod
}

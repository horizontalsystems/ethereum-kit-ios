public class UnknownMethodDecoration: ContractMethodDecoration {
    public let methodId: Data
    public let inputArguments: Data

    init(methodId: Data, inputArguments: Data) {
        self.methodId = methodId
        self.inputArguments = inputArguments
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        []
    }

}

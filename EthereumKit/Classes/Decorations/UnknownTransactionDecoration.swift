public class UnknownTransactionDecoration: TransactionDecoration {
    public let methodId: Data
    public let inputArguments: Data

    init(methodId: Data, inputArguments: Data) {
        self.methodId = methodId
        self.inputArguments = inputArguments
    }

}

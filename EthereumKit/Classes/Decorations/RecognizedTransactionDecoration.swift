public class RecognizedTransactionDecoration: TransactionDecoration {
    public let method: String
    public let arguments: [Any]

    init(method: String, arguments: [Any]) {
        self.method = method
        self.arguments = arguments

        super.init()
        tags.append(method)
    }

}

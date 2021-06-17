public class RecognizedMethodDecoration: ContractMethodDecoration {
    public let method: String
    public let arguments: [Any]

    init(method: String, arguments: [Any]) {
        self.method = method
        self.arguments = arguments

        super.init()
    }

    public override func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        [toAddress.hex, method]
    }

}

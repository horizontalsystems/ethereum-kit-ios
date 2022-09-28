public class TransactionTagQuery {
    public let type: TransactionTag.TagType?
    public let `protocol`: TransactionTag.TagProtocol?
    public let contractAddress: Address?

    public init(type: TransactionTag.TagType? = nil, `protocol`: TransactionTag.TagProtocol? = nil, contractAddress: Address? = nil) {
        self.type = type
        self.protocol = `protocol`
        self.contractAddress = contractAddress
    }

    var isEmpty: Bool {
        type == nil && `protocol` == nil && contractAddress == nil
    }

}

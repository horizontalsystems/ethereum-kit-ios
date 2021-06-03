open class EventDecoration {
    public let contractAddress: Address

    public init(contractAddress: Address) {
        self.contractAddress = contractAddress
    }

    open var tags: [String] {
        fatalError("Must be implemented by subclass")
    }

}

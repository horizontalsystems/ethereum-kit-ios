open class TransactionDecoration {

    public init() {}

    open func tags(fromAddress: Address, toAddress: Address, userAddress: Address) -> [String] {
        fatalError("Method must be implemented by subclass")
    }

}

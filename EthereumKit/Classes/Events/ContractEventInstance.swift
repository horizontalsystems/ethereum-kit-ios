open class ContractEventInstance {
    public let contractAddress: Address

    public init(contractAddress: Address) {
        self.contractAddress = contractAddress
    }

    open func tags(userAddress: Address) -> [String] {
        []
    }

}

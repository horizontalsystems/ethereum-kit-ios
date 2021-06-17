open class ContractEventDecoration: TransactionDecoration {
    public let contractAddress: Address

    public init(contractAddress: Address) {
        self.contractAddress = contractAddress
    }

}

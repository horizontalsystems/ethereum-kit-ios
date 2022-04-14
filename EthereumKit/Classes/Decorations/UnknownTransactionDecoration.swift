import BigInt

open class UnknownTransactionDecoration: TransactionDecoration {
    private let userAddress: Address
    private let value: BigUInt?

    public let internalTransactions: [InternalTransaction]
    public let eventInstances: [ContractEventInstance]

    public init(userAddress: Address, value: BigUInt?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) {
        self.userAddress = userAddress
        self.value = value
        self.internalTransactions = internalTransactions
        self.eventInstances = eventInstances
    }

    open override func tags() -> [String] {
        Array(Set(tagsFromInternalTransactions + tagsFromEventInstances))
    }

    private var tagsFromInternalTransactions: [String] {
        let incomingInternalTransactions = internalTransactions.filter { $0.to == userAddress }

        guard !incomingInternalTransactions.isEmpty else {
            return []
        }

        var totalAmount: BigUInt = 0

        incomingInternalTransactions.forEach {
            totalAmount += $0.value
        }

        guard totalAmount > (value ?? 0) else {
            return []
        }

        return ["\(TransactionTag.evmCoin)_incoming", TransactionTag.evmCoin, "incoming"]
    }

    private var tagsFromEventInstances: [String] {
        var tags = [String]()

        for eventInstance in eventInstances {
            tags.append(contentsOf: eventInstance.tags(userAddress: userAddress))
        }

        return tags
    }

}

import BigInt

open class UnknownTransactionDecoration: TransactionDecoration {
    private let userAddress: Address
    private let toAddress: Address?
    public let fromAddress: Address?
    private let value: BigUInt?

    public let internalTransactions: [InternalTransaction]
    public let eventInstances: [ContractEventInstance]

    public init(userAddress: Address, fromAddress: Address?, toAddress: Address?, value: BigUInt?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) {
        self.userAddress = userAddress
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.value = value
        self.internalTransactions = internalTransactions
        self.eventInstances = eventInstances
    }

    open override func tags() -> [String] {
        Array(Set(tagsFromInternalTransactions + tagsFromEventInstances))
    }

    private var tagsFromInternalTransactions: [String] {
        let value = value ?? 0
        let incomingInternalTransactions = internalTransactions.filter { $0.to == userAddress }

        var outgoingValue: BigUInt = 0
        if fromAddress == userAddress {
            outgoingValue = value
        }
        var incomingValue: BigUInt = 0
        if toAddress == userAddress {
            incomingValue = value
        }
        incomingInternalTransactions.forEach {
            incomingValue += $0.value
        }

        // if has value or has internalTxs must add Evm tag
        if outgoingValue == 0 && incomingValue == 0 {
            return []
        }
        var tags = [TransactionTag.evmCoin]

        if incomingValue > outgoingValue {
            tags.append(contentsOf: ["\(TransactionTag.evmCoin)_incoming", "incoming"] )
        }
        if outgoingValue > incomingValue {
            tags.append(contentsOf: ["\(TransactionTag.evmCoin)_outgoing", "outgoing"])
        }

        return tags
    }

    private var tagsFromEventInstances: [String] {
        var tags = [String]()

        for eventInstance in eventInstances {
            tags.append(contentsOf: eventInstance.tags(userAddress: userAddress))
        }

        return tags
    }

}

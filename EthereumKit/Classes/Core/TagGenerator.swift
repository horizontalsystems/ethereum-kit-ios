class TagGenerator {
    private let address: Address

    init(address: Address) {
        self.address = address
    }

    private func generateFromMain(fullTransaction: FullTransaction) -> [String] {
        let transaction = fullTransaction.transaction

        guard let value = transaction.value, let from = transaction.from else {
            return []
        }

        guard let to = transaction.to else {
            return ["contractCreation"]
        }

        var tags = [String]()

        if value > 0, from == address {
            tags.append(contentsOf: ["\(TransactionTag.evmCoin)_outgoing", TransactionTag.evmCoin, "outgoing"])
        }

        if to == address || fullTransaction.internalTransactions.contains(where: { $0.to == address }) {
            tags.append(contentsOf: ["\(TransactionTag.evmCoin)_incoming", TransactionTag.evmCoin, "incoming"])
        }

        if let mainDecoration = fullTransaction.mainDecoration {
            tags.append(contentsOf: mainDecoration.tags(fromAddress: from, toAddress: to, userAddress: address))
        }

        return tags
    }

    private func generateFromEvents(fullTransaction: FullTransaction) -> [String] {
        let transaction = fullTransaction.transaction
        var tags = [String]()

        for event in fullTransaction.eventDecorations {
            tags.append(contentsOf: event.tags(userAddress: address))
        }

        return tags
    }

}

extension TagGenerator {

    func generate(for fullTransaction: FullTransaction) -> [TransactionTag] {
        let tags = generateFromMain(fullTransaction: fullTransaction) + generateFromEvents(fullTransaction: fullTransaction)
        let uniqueTags = Array(Set(tags))

        return uniqueTags.map { tag in
            TransactionTag(
                    name: tag,
                    transactionHash: fullTransaction.transaction.hash
            )
        }
    }

}

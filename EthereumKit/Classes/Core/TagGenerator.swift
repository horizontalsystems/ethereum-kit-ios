class TagGenerator {
    private let address: Address

    init(address: Address) {
        self.address = address
    }

}

extension TagGenerator {

    func generate(for fullTransaction: FullTransaction) -> [TransactionTag] {
        let transaction = fullTransaction.transaction

        guard let toAddress = transaction.to else {
            return [TransactionTag(name: "contractCreation", transactionHash: transaction.hash)]
        }

        var tags = [String]()

        if transaction.from == address && transaction.value > 0 {
            tags.append(contentsOf: ["\(TransactionTag.evmCoin)_outgoing", TransactionTag.evmCoin, "outgoing"])
        }

        if toAddress == address || fullTransaction.internalTransactions.contains(where: { $0.to == address }) {
            tags.append(contentsOf: ["\(TransactionTag.evmCoin)_incoming", TransactionTag.evmCoin, "incoming"])
        }

        if let mainDecoration = fullTransaction.mainDecoration, !(mainDecoration is UnknownMethodDecoration) {
            tags.append(contentsOf: mainDecoration.tags(fromAddress: transaction.from, toAddress: toAddress, userAddress: address))
        }

        for event in fullTransaction.eventDecorations {
            tags.append(contentsOf: event.tags(fromAddress: transaction.from, toAddress: toAddress, userAddress: address))
        }

        return Array(Set(tags)).map({ TransactionTag(name: $0, transactionHash: transaction.hash) })
    }

}

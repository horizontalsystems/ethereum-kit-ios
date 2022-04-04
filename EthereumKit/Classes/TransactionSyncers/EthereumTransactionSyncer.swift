import RxSwift
import BigInt

class EthereumTransactionSyncer {
    private let provider: ITransactionProvider

    init(provider: ITransactionProvider) {
        self.provider = provider
    }

}

extension EthereumTransactionSyncer: ITransactionSyncer {

    func transactionsSingle(lastBlockNumber: Int) -> Single<[Transaction]> {
        provider.transactionsSingle(startBlock: lastBlockNumber + 1)
                .map { transactions in
                    transactions.map { tx in
                        var isFailed: Bool

                        if let status = tx.txReceiptStatus {
                            isFailed = status != 1
                        } else if let isError = tx.isError {
                            isFailed = isError != 0
                        } else if let gasUsed = tx.gasUsed {
                            isFailed = tx.gasLimit == gasUsed
                        } else {
                            isFailed = false
                        }

                        return Transaction(
                                hash: tx.hash,
                                timestamp: tx.timestamp,
                                isFailed: isFailed,
                                blockNumber: tx.blockNumber,
                                transactionIndex: tx.transactionIndex,
                                from: tx.from,
                                to: tx.to,
                                value: tx.value,
                                input: tx.input,
                                nonce: tx.nonce,
                                gasPrice: tx.gasPrice,
                                gasUsed: tx.gasUsed
                        )
                    }
                }
    }

}

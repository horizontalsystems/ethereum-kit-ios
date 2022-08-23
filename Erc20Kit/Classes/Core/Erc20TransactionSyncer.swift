import RxSwift
import BigInt
import EthereumKit

class Erc20TransactionSyncer {
    private let provider: ITransactionProvider
    private let storage: Eip20Storage

    init(provider: ITransactionProvider, storage: Eip20Storage) {
        self.provider = provider
        self.storage = storage
    }

    private func handle(transactions: [ProviderTokenTransaction]) {
        guard !transactions.isEmpty else {
            return
        }

        let events = transactions.map { tx in
            Event(
                    hash: tx.hash,
                    blockNumber: tx.blockNumber,
                    contractAddress: tx.contractAddress,
                    from: tx.from,
                    to: tx.to,
                    value: tx.value,
                    tokenName: tx.tokenName,
                    tokenSymbol: tx.tokenSymbol,
                    tokenDecimal: tx.tokenDecimal
            )
        }

        storage.save(events: events)
    }

}

extension Erc20TransactionSyncer: ITransactionSyncer {

    public func transactionsSingle() -> Single<([Transaction], Bool)> {
        let lastBlockNumber = storage.lastEvent()?.blockNumber ?? 0
        let initial = lastBlockNumber == 0

        return provider.tokenTransactionsSingle(startBlock: lastBlockNumber + 1)
                .do(onSuccess: { [weak self] transactions in
                    self?.handle(transactions: transactions)
                })
                .map { transactions in
                    let array = transactions.map { tx in
                        Transaction(
                                hash: tx.hash,
                                timestamp: tx.timestamp,
                                isFailed: false,
                                blockNumber: tx.blockNumber,
                                transactionIndex: tx.transactionIndex,
                                nonce: tx.nonce,
                                gasPrice: tx.gasPrice,
                                gasLimit: tx.gasLimit,
                                gasUsed: tx.gasUsed
                        )
                    }

                    return (array, initial)
                }
                .catchErrorJustReturn(([], initial))
    }

}

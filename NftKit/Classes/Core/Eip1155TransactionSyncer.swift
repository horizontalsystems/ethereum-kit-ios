import RxSwift
import BigInt
import EthereumKit

class Eip1155TransactionSyncer {
    private let provider: ITransactionProvider
    private let storage: Storage

    weak var delegate: ITransactionSyncerDelegate?

    init(provider: ITransactionProvider, storage: Storage) {
        self.provider = provider
        self.storage = storage
    }

    private func handle(transactions: [ProviderEip1155Transaction]) {
        guard !transactions.isEmpty else {
            return
        }

        let events = transactions.map { tx in
            Eip1155Event(
                    hash: tx.hash,
                    blockNumber: tx.blockNumber,
                    contractAddress: tx.contractAddress,
                    from: tx.from,
                    to: tx.to,
                    tokenId: tx.tokenId,
                    tokenValue: tx.tokenValue,
                    tokenName: tx.tokenName,
                    tokenSymbol: tx.tokenSymbol
            )
        }

        try? storage.save(eip1155Events: events)

        let nfts = Set<Nft>(events.map { event in
            Nft(
                    type: .eip1155,
                    contractAddress: event.contractAddress,
                    tokenId: event.tokenId,
                    tokenName: event.tokenName
            )
        })

        delegate?.didSync(nfts: Array(nfts), type: .eip1155)
    }

}

extension Eip1155TransactionSyncer: ITransactionSyncer {

    func transactionsSingle() -> Single<([Transaction], Bool)> {
        let lastBlockNumber = (try? storage.lastEip1155Event()?.blockNumber) ?? 0
        let initial = lastBlockNumber == 0

        return provider.eip1155TransactionsSingle(startBlock: lastBlockNumber + 1)
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

import RxSwift
import BigInt
import EthereumKit

class Erc20TransactionSyncer {
    private let provider: ITransactionProvider
    private let evmKit: EthereumKit.Kit

    init(provider: ITransactionProvider, evmKit: EthereumKit.Kit) {
        self.provider = provider
        self.evmKit = evmKit
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

        evmKit.save(events: events)
    }

}

extension Erc20TransactionSyncer: ITransactionSyncer {

    public func transactionsSingle() -> Single<[Transaction]> {
        let lastBlockNumber = evmKit.lastEvent()?.blockNumber ?? 0

        return provider.tokenTransactionsSingle(startBlock: lastBlockNumber + 1)
                .do(onSuccess: { [weak self] transactions in
                    self?.handle(transactions: transactions)
                })
                .map { transactions in
                    transactions.map { tx in
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
                }
    }

}

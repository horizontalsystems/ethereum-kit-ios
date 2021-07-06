import EthereumKit
import RxSwift
import BigInt

class OneInchInternalTransactionSyncer {

    private let disposeBag = DisposeBag()
    private weak var evmKit: EthereumKit.Kit?

    private var syncingTransactions = [Data: Int]()
    private let maxRetryCount = 3
    private let delayTime: UInt32 = 10 // seconds

    init(evmKit: EthereumKit.Kit) {
        self.evmKit = evmKit

        evmKit.allTransactionsObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] transactions in
                    for transaction in transactions {
                        self?.handle(fullTransaction: transaction)
                    }
                })
                .disposed(by: disposeBag)
    }


    private func handle(fullTransaction: FullTransaction) {
        guard fullTransaction.internalTransactions.isEmpty,
              let mainDecoration = fullTransaction.mainDecoration as? OneInchSwapMethodDecoration,
              let evmKit = evmKit,
              case .evmCoin = mainDecoration.tokenOut,
              fullTransaction.transaction.from == evmKit.address && mainDecoration.recipient != evmKit.address else {
            return
        }

        let transaction = fullTransaction.transaction

        if let count = syncingTransactions[transaction.hash] {
            if count < maxRetryCount {
                sleep(delayTime)
                syncingTransactions[transaction.hash] = count + 1
            } else {
                return
            }
        } else {
            syncingTransactions[transaction.hash] = 1
        }

        evmKit.syncInternalTransactions(for: transaction)
    }

}

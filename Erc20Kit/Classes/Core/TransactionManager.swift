import EthereumKit
import BigInt
import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let contractAddress: Address
    private let contractMethodFactories: Eip20ContractMethodFactories
    private let address: Address
    private let tags: [[String]]

    private let transactionsSubject = PublishSubject<[FullTransaction]>()

    var transactionsObservable: Observable<[FullTransaction]> {
        transactionsSubject.asObservable()
    }

    init(ethereumKit: EthereumKit.Kit, contractAddress: Address, contractMethodFactories: Eip20ContractMethodFactories) {
        self.ethereumKit = ethereumKit
        self.contractAddress = contractAddress
        self.contractMethodFactories = contractMethodFactories

        address = ethereumKit.receiveAddress
        tags = [[contractAddress.hex]]

        ethereumKit.allTransactionsObservable
                .subscribe { [weak self] in
                    self?.processTransactions(fullTransactions: $0)
                }
                .disposed(by: disposeBag)
    }

    private func processTransactions(fullTransactions: [FullTransaction]) {
        let erc20Transactions = fullTransactions.filter { fullTransaction in
            let transaction = fullTransaction.transaction

            if let decoration = fullTransaction.mainDecoration {
                switch decoration {
                case let transfer as TransferMethodDecoration:
                    return transfer.to == address || transaction.from == address

                case is ApproveMethodDecoration: return transaction.from == address

                default: return false
                }
            }

            for decoration in fullTransaction.eventDecorations {
                switch decoration {
                case let transfer as TransferEventDecoration:
                    return transfer.from == address || transfer.to == address

                case let approve as ApproveEventDecoration:
                    return approve.owner == address

                default: return false
                }
            }

            return false
        }

        if !erc20Transactions.isEmpty {
            transactionsSubject.onNext(erc20Transactions)
        }

        if let lastSyncOrder = fullTransactions.sorted(by: { a, b in a.transaction.syncOrder > b.transaction.syncOrder }).first {
            ethereumKit.save(transactionSyncOrder: lastSyncOrder.transaction.syncOrder, contractAddress: contractAddress)
        }
    }

}

extension TransactionManager: ITransactionManager {

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        ethereumKit.transactionsSingle(tags: tags, fromHash: hash, limit: limit)
    }

    func pendingTransactions() -> [FullTransaction] {
        ethereumKit.pendingTransactions(tags: tags)
    }

    func transferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: TransferMethod(to: to, value: value).encodedABI()
        )
    }

    func sync() {
        let lastSyncOrder = ethereumKit.transactionSyncOrder(contractAddress: contractAddress)
        let fullTransactions = ethereumKit.fullTransactions(fromSyncOrder: lastSyncOrder)

        processTransactions(fullTransactions: fullTransactions)
    }

}

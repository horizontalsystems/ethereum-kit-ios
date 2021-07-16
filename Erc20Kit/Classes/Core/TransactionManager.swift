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

        ethereumKit.transactionsObservable(tags: [[contractAddress.hex]])
                .subscribe { [weak self] in
                    self?.processTransactions(erc20Transactions: $0)
                }
                .disposed(by: disposeBag)
    }

    private func processTransactions(erc20Transactions: [FullTransaction]) {
        guard !erc20Transactions.isEmpty else {
            return
        }

        transactionsSubject.onNext(erc20Transactions)
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

}

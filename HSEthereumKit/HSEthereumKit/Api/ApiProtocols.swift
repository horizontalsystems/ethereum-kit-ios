import RxSwift

protocol IApiProvider {
    func lastBlockHeightSingle() -> Single<Int>
    func transactionCountSingle(address: Data) -> Single<Int>

    func balanceSingle(address: Data) -> Single<BInt>
    func balanceErc20Single(address: Data, contractAddress: Data) -> Single<BInt>

    func transactionsSingle(address: Data, startBlock: Int) -> Single<[Transaction]>
    func transactionsErc20Single(address: Data, startBlock: Int) -> Single<[Transaction]>

    func sendSingle(signedTransaction: Data) -> Single<Void>
}

protocol IApiStorage: IStorage {
    var lastBlockHeight: Int? { get }
    func save(lastBlockHeight: Int)

    func balance(forAddress address: Data) -> BInt?
    func save(balance: BInt, address: Data)

    func lastTransactionBlockHeight(erc20: Bool) -> Int?
}

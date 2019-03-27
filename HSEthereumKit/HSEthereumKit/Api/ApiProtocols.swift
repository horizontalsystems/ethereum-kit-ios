import RxSwift

protocol IApiProvider {
    func lastBlockHeightSingle() -> Single<Int>
    func transactionCountSingle(address: String) -> Single<Int>

    func balanceSingle(address: String) -> Single<String>
    func balanceErc20Single(address: String, contractAddress: String) -> Single<String>

    func transactionsSingle(address: String, startBlock: Int64) -> Single<[EthereumTransaction]>
    func transactionsErc20Single(address: String, startBlock: Int64) -> Single<[EthereumTransaction]>

    func sendSingle(signedTransactionHex: String) -> Single<Void>
}

protocol IApiStorage {
    var lastBlockHeight: Int? { get }

    func balance(forAddress address: String) -> String?
    func transactionsSingle(fromHash: String?, limit: Int?, contractAddress: String?) -> Single<[EthereumTransaction]>

    func lastTransactionBlockHeight(erc20: Bool) -> Int?

    func save(lastBlockHeight: Int)
    func save(balance: String, address: String)
    func save(transactions: [EthereumTransaction])

    func clear()
}

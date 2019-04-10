import RxSwift

protocol IRpcApiProvider {
    func lastBlockHeightSingle() -> Single<Int>
    func transactionCountSingle(address: Data) -> Single<Int>
    func balanceSingle(address: Data) -> Single<BInt>
    func sendSingle(signedTransaction: Data) -> Single<Void>
    func getStorageAt(contractAddress: String, position: String, blockNumber: Int?) -> Single<String>
    func getLogs(address: Data?, fromBlock: Int?, toBlock: Int?, topics: [Any]) -> Single<[EthereumLog]>
    func getBlock(byNumber: Int) -> Single<Block>
}

protocol IApiStorage: IStorage {
    var lastBlockHeight: Int? { get }
    func save(lastBlockHeight: Int)

    func balance(forAddress address: Data) -> BInt?
    func save(balance: BInt, address: Data)

    func lastTransactionBlockHeight() -> Int?
}

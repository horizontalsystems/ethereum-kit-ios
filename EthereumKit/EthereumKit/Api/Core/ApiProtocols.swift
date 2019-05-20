import RxSwift
import BigInt

protocol IRpcApiProvider {
    func lastBlockHeightSingle() -> Single<Int>
    func transactionCountSingle() -> Single<Int>
    func balanceSingle() -> Single<BigUInt>
    func sendSingle(signedTransaction: Data) -> Single<Void>
    func getLogs(address: Data?, fromBlock: Int?, toBlock: Int?, topics: [Any]) -> Single<[EthereumLog]>
    func getStorageAt(contractAddress: String, position: String, blockNumber: Int?) -> Single<String>
    func call(contractAddress: String, data: String, blockNumber: Int?) -> Single<String>
    func getBlock(byNumber: Int) -> Single<Block>
}

protocol IApiStorage: IStorage {
    var lastBlockHeight: Int? { get }
    func save(lastBlockHeight: Int)

    var balance: BigUInt? { get }
    func save(balance: BigUInt)

    func lastTransactionBlockHeight() -> Int?
}

import RxSwift
import BigInt

protocol IRpcApiProvider {
    var source: String { get }

    func lastBlockHeightSingle() -> Single<Int>
    func transactionCountSingle() -> Single<Int>
    func balanceSingle() -> Single<BigUInt>
    func sendSingle(signedTransaction: Data) -> Single<Void>
    func getLogs(address: Data?, fromBlock: Int, toBlock: Int, topics: [Any?]) -> Single<[EthereumLog]>
    func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus>
    func transactionExistSingle(transactionHash: Data) -> Single<Bool>
    func getStorageAt(contractAddress: String, position: String, blockNumber: Int?) -> Single<Data>
    func call(contractAddress: String, data: String, blockNumber: Int?) -> Single<Data>
    func getEstimateGas(from: String?, contractAddress: String, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: String?) -> Single<Int>
    func getBlock(byNumber: Int) -> Single<Block>
}

protocol IApiStorage {
    var lastBlockHeight: Int? { get }
    func save(lastBlockHeight: Int)

    var balance: BigUInt? { get }
    func save(balance: BigUInt)
}

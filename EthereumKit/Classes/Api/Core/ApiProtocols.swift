import RxSwift
import BigInt

protocol IRpcApiProvider {
    var source: String { get }

    func lastBlockHeightSingle() -> Single<Int>
    func transactionCountSingle() -> Single<Int>
    func balanceSingle() -> Single<BigUInt>
    func sendSingle(signedTransaction: Data) -> Single<Void>
    func getLogs(address: Address?, fromBlock: Int, toBlock: Int, topics: [Any?]) -> Single<[EthereumLog]>
    func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus>
    func transactionExistSingle(transactionHash: Data) -> Single<Bool>
    func getStorageAt(contractAddress: Address, position: String, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func call(contractAddress: Address, data: String, defaultBlockParameter: DefaultBlockParameter) -> Single<Data>
    func getEstimateGas(to: Address, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int>
    func getBlock(byNumber: Int) -> Single<Block>
}

protocol IApiStorage {
    var lastBlockHeight: Int? { get }
    func save(lastBlockHeight: Int)

    var balance: BigUInt? { get }
    func save(balance: BigUInt)
}

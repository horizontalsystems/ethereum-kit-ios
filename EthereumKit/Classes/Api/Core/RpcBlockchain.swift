import RxSwift
import BigInt
import HsToolKit

class RpcBlockchain {
    private var disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let address: Address
    private let storage: IApiStorage
    private let syncer: IRpcSyncer
    private let transactionSigner: TransactionSigner
    private let transactionBuilder: TransactionBuilder
    private var logger: Logger?

    init(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, logger: Logger? = nil) {
        self.address = address
        self.storage = storage
        self.syncer = syncer
        self.transactionSigner = transactionSigner
        self.transactionBuilder = transactionBuilder
        self.logger = logger
    }

//    private func pullTransactionTimestamps(ethereumLogs: [EthereumLog]) -> Single<[EthereumLog]> {
//        let logsByBlockNumber = Dictionary(grouping: ethereumLogs, by: { $0.blockNumber })
//
//        var requestSingles = [Single<Block>]()
//        for blockNumber in logsByBlockNumber.keys {
//            requestSingles.append(syncer.single(rpc: GetBlockByNumberJsonRpc(number: blockNumber)))
//        }
//
//        return Single.zip(requestSingles)
//                .map { (blocks: [Block]) in
//                    var resultLogs = [EthereumLog]()
//
//                    for block in blocks {
//                        guard let logsOfBlock = logsByBlockNumber[block.number] else {
//                            continue
//                        }
//
//                        for log in logsOfBlock {
//                            log.timestamp = Double(block.timestamp)
//                            resultLogs.append(log)
//                        }
//                    }
//
//                    return resultLogs
//                }
//    }

}

extension RpcBlockchain: IRpcSyncerDelegate {

    func didUpdate(syncState: SyncState) {
        delegate?.onUpdate(syncState: syncState)
    }

    func didUpdate(lastBlockLogsBloom: String) {
        let bloomFilter = BloomFilter(filter: lastBlockLogsBloom)

        guard bloomFilter.mayContain(userAddress: address) else {
            return
        }

        delegate?.onUpdate(lastBlockBloomFilter: bloomFilter)
    }

    func didUpdate(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    func didUpdate(balance: BigUInt) {
        storage.save(balance: balance)
        delegate?.onUpdate(balance: balance)
    }

    func didUpdate(nonce: Int) {
        delegate?.onUpdate(nonce: nonce)
    }

}

extension RpcBlockchain: IBlockchain {

    var source: String {
        "RPC \(syncer.source)"
    }

    var syncState: SyncState {
        syncer.syncState
    }

    func start() {
        syncer.start()
    }

    func stop() {
        syncer.stop()
    }

    func refresh() {
        syncer.refresh()
    }

    var lastBlockHeight: Int? {
        storage.lastBlockHeight
    }

    var balance: BigUInt? {
        storage.balance
    }

    func nonceSingle() -> Single<Int> {
        syncer.single(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: .pending))
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
        do {
            let signature = try transactionSigner.signature(rawTransaction: rawTransaction)
            let transaction = transactionBuilder.transaction(rawTransaction: rawTransaction, signature: signature)
            let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)

            return syncer.single(rpc: SendRawTransactionJsonRpc(signedTransaction: encoded))
                    .map { _ in
                        transaction
                    }
        } catch {
            return Single.error(error)
        }
    }

    func getLogsSingle(address: Address?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
        syncer.single(rpc: GetLogsJsonRpc(address: address, fromBlock: .blockNumber(value: fromBlock), toBlock: .blockNumber(value: toBlock), topics: topics))
                .flatMap { [unowned self] logs in
                    Single.just(logs)

//                    if pullTimestamps {
//                        return self.pullTransactionTimestamps(ethereumLogs: logs)
//                    } else {
//                        return Single.just(logs)
//                    }
                }
    }

    func transactionReceiptSingle(transactionHash: Data) -> Single<TransactionReceipt?> {
        syncer.single(rpc: GetTransactionReceiptJsonRpc(transactionHash: transactionHash))
    }

    func transactionSingle(transactionHash: Data) -> Single<RpcTransaction?> {
        syncer.single(rpc: GetTransactionByHashJsonRpc(transactionHash: transactionHash))
    }

    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        syncer.single(rpc: GetStorageAtJsonRpc(contractAddress: contractAddress, positionData: positionData, defaultBlockParameter: defaultBlockParameter))
    }

    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        syncer.single(rpc: CallJsonRpc(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter))
    }

    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int> {
        syncer.single(rpc: EstimateGasJsonRpc(from: address, to: to, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, data: data))
    }

}

extension RpcBlockchain {

    static func instance(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, logger: Logger? = nil) -> RpcBlockchain {
        let blockchain = RpcBlockchain(address: address, storage: storage, syncer: syncer, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, logger: logger)
        syncer.delegate = blockchain
        return blockchain
    }

}

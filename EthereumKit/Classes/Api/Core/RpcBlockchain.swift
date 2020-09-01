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
    private let reachabilityManager: IReachabilityManager
    private var logger: Logger?

    private var isStarted = false

    init(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, reachabilityManager: IReachabilityManager, logger: Logger? = nil) {
        self.address = address
        self.storage = storage
        self.syncer = syncer
        self.transactionSigner = transactionSigner
        self.transactionBuilder = transactionBuilder
        self.reachabilityManager = reachabilityManager
        self.logger = logger

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncSyncer()
                })
                .disposed(by: disposeBag)
    }

    private func sendSingle(rawTransaction: RawTransaction, nonce: Int) throws -> Single<Transaction> {
        let signature = try transactionSigner.signature(rawTransaction: rawTransaction, nonce: nonce)
        let transaction = transactionBuilder.transaction(rawTransaction: rawTransaction, nonce: nonce, signature: signature)
        let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature, nonce: nonce)

        return syncer.single(rpc: SendRawTransactionJsonRpc(signedTransaction: encoded))
                .map { _ in
                    transaction
                }
    }

    private func pullTransactionTimestamps(ethereumLogs: [EthereumLog]) -> Single<[EthereumLog]> {
        let logsByBlockNumber = Dictionary(grouping: ethereumLogs, by: { $0.blockNumber })

        var requestSingles = [Single<Block>]()
        for blockNumber in logsByBlockNumber.keys {
            requestSingles.append(syncer.single(rpc: GetBlockByNumberJsonRpc(number: blockNumber)))
        }

        return Single.zip(requestSingles)
                .map { (blocks: [Block]) in
                    var resultLogs = [EthereumLog]()

                    for block in blocks {
                        guard let logsOfBlock = logsByBlockNumber[block.number] else {
                            continue
                        }

                        for log in logsOfBlock {
                            log.timestamp = Double(block.timestamp)
                            resultLogs.append(log)
                        }
                    }

                    return resultLogs
                }
    }

    private func syncSyncer() {
        guard isStarted else {
            return
        }

        if reachabilityManager.isReachable {
            syncer.start()
        } else {
            syncer.stop(error: Kit.SyncError.noNetworkConnection)
        }
    }

}

extension RpcBlockchain: IRpcSyncerDelegate {

    func didUpdate(syncState: SyncState) {
        delegate?.onUpdate(syncState: syncState)
    }

    func didUpdate(lastBlockLogsBloom: String) {
        delegate?.onUpdate(lastBlockLogsBloom: lastBlockLogsBloom)
    }

    func didUpdate(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    func didUpdate(balance: BigUInt) {
        storage.save(balance: balance)
        delegate?.onUpdate(balance: balance)
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
        guard !isStarted else {
            return
        }

        isStarted = true
        syncSyncer()
    }

    func stop() {
        guard isStarted else {
            return
        }

        isStarted = false

        syncer.stop(error: Kit.SyncError.notStarted)
    }

    func refresh() {
        guard isStarted, reachabilityManager.isReachable else {
            return
        }

        syncer.refresh()
    }

    var lastBlockHeight: Int? {
        storage.lastBlockHeight
    }

    var balance: BigUInt? {
        storage.balance
    }

    func sendSingle(rawTransaction: RawTransaction) -> Single<Transaction> {
        syncer.single(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: .pending))
                .flatMap { [unowned self] nonce -> Single<Transaction> in
                    try self.sendSingle(rawTransaction: rawTransaction, nonce: nonce)
                }
                .do(onSuccess: { [weak self] transaction in
//                    self?.sync() // todo: check is sync is required
                })
    }

    func getLogsSingle(address: Address?, topics: [Any?], fromBlock: Int, toBlock: Int, pullTimestamps: Bool) -> Single<[EthereumLog]> {
        syncer.single(rpc: GetLogsJsonRpc(address: address, fromBlock: fromBlock, toBlock: toBlock, topics: topics))
                .flatMap { [unowned self] logs in
                    if pullTimestamps {
                        return self.pullTransactionTimestamps(ethereumLogs: logs)
                    } else {
                        return Single.just(logs)
                    }
                }
    }

    func transactionReceiptStatusSingle(transactionHash: Data) -> Single<TransactionStatus> {
        syncer.single(rpc: GetTransactionReceiptJsonRpc(transactionHash: transactionHash))
                .map { resultMap in
                    guard let resultMap = resultMap, let statusString = resultMap["status"] as? String, let success = Int(statusString.stripHexPrefix(), radix: 16) else {
                        return .notFound
                    }
                    return success == 0 ? .failed : .success
                }
    }

    func transactionExistSingle(transactionHash: Data) -> Single<Bool> {
        syncer.single(rpc: GetTransactionByHashJsonRpc(transactionHash: transactionHash))
                .map { $0 != nil }
    }

    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        syncer.single(rpc: GetStorageAtJsonRpc(contractAddress: contractAddress, positionData: positionData, defaultBlockParameter: defaultBlockParameter))
    }

    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        syncer.single(rpc: CallJsonRpc(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter))
    }

    func estimateGas(to: Address, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) -> Single<Int> {
        syncer.single(rpc: EstimateGasJsonRpc(from: address, to: to, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, data: data))
    }

}

extension RpcBlockchain {

    static func instance(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, logger: Logger? = nil) -> RpcBlockchain {
        let reachabilityManager = ReachabilityManager()
        let blockchain = RpcBlockchain(address: address, storage: storage, syncer: syncer, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, reachabilityManager: reachabilityManager, logger: logger)
        syncer.delegate = blockchain
        return blockchain
    }

}

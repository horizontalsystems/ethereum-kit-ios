import Foundation
import RxSwift
import BigInt
import HsToolKit

class RpcBlockchain {
    private var disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let address: Address
    private let storage: IApiStorage
    private let syncer: IRpcSyncer
    private let transactionBuilder: TransactionBuilder
    private var logger: Logger?

    private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                delegate?.onUpdate(syncState: syncState)
            }
        }
    }

    private var synced = false

    init(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionBuilder: TransactionBuilder, logger: Logger? = nil) {
        self.address = address
        self.storage = storage
        self.syncer = syncer
        self.transactionBuilder = transactionBuilder
        self.logger = logger
    }

    private func syncLastBlockHeight() {
        syncer.single(rpc: BlockNumberJsonRpc())
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] lastBlockHeight in
                    self?.onUpdate(lastBlockHeight: lastBlockHeight)
                }, onError: { _ in
                    // todo
                })
                .disposed(by: disposeBag)
    }

    private func onUpdate(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    func onUpdate(accountState: AccountState) {
        storage.save(accountState: accountState)
        delegate?.onUpdate(accountState: accountState)
    }

}

extension RpcBlockchain: IRpcSyncerDelegate {

    func didUpdate(state: SyncerState) {
        switch state {
        case .preparing:
            syncState = .syncing(progress: nil)
        case .ready:
            syncState = .syncing(progress: nil)
            syncAccountState()
            syncLastBlockHeight()
        case .notReady(let error):
            disposeBag = DisposeBag()
            syncState = .notSynced(error: error)
        }
    }

    func didUpdate(lastBlockHeight: Int) {
        onUpdate(lastBlockHeight: lastBlockHeight)
        // report to whom???
    }

}

extension RpcBlockchain: IBlockchain {

    var source: String {
        "RPC \(syncer.source)"
    }

    func start() {
        syncState = .syncing(progress: nil)
        syncer.start()
    }

    func stop() {
        syncer.stop()
    }

    func refresh() {
        switch syncer.state {
        case .preparing:
            ()
        case .ready:
            syncAccountState()
            syncLastBlockHeight()
        case .notReady:
            syncer.start()
        }
    }

    func syncAccountState() {
        Single.zip(
                        syncer.single(rpc: GetBalanceJsonRpc(address: address, defaultBlockParameter: .latest)),
                        syncer.single(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: .latest))
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] balance, nonce in
                    self?.onUpdate(accountState: AccountState(balance: balance, nonce: nonce))
                    self?.syncState = .synced
                }, onError: { [weak self] error in
                    guard let webSocketError = error as? HsToolKit.WebSocketStateError else {
                        self?.syncState = .notSynced(error: error)
                        return
                    }

                    switch webSocketError {
                    case .connecting:
                        self?.syncState = .syncing(progress: nil)
                    case .couldNotConnect:
                        self?.syncState = .notSynced(error: webSocketError)
                    }
                })
                .disposed(by: disposeBag)
    }

    var lastBlockHeight: Int? {
        storage.lastBlockHeight
    }

    var accountState: AccountState? {
        storage.accountState
    }

    func nonceSingle(defaultBlockParameter: DefaultBlockParameter) -> Single<Int> {
        syncer.single(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: defaultBlockParameter))
    }

    func sendSingle(rawTransaction: RawTransaction, signature: Signature) -> Single<Transaction> {
        let transaction = transactionBuilder.transaction(rawTransaction: rawTransaction, signature: signature)
        let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)

        return syncer.single(rpc: SendRawTransactionJsonRpc(signedTransaction: encoded))
                .map { _ in
                    transaction
                }
    }

    func transactionReceiptSingle(transactionHash: Data) -> Single<RpcTransactionReceipt> {
        syncer.single(rpc: GetTransactionReceiptJsonRpc(transactionHash: transactionHash))
    }

    func transactionSingle(transactionHash: Data) -> Single<RpcTransaction> {
        syncer.single(rpc: GetTransactionByHashJsonRpc(transactionHash: transactionHash))
    }

    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        syncer.single(rpc: GetStorageAtJsonRpc(contractAddress: contractAddress, positionData: positionData, defaultBlockParameter: defaultBlockParameter))
    }

    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> Single<Data> {
        syncer.single(rpc: Self.callRpc(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter))
    }

    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: GasPrice, data: Data?) -> Single<Int> {
        syncer.single(rpc: EstimateGasJsonRpc(from: address, to: to, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, data: data))
    }

    func getBlock(blockNumber: Int) -> Single<RpcBlock> {
        syncer.single(rpc: GetBlockByNumberJsonRpc(number: blockNumber))
    }

    func rpcSingle<T>(rpcRequest: JsonRpc<T>) -> Single<T> {
        syncer.single(rpc: rpcRequest)
    }

}

extension RpcBlockchain {

    static func callRpc(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> JsonRpc<Data> {
        CallJsonRpc(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
    }

}

extension RpcBlockchain {

    static func instance(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionBuilder: TransactionBuilder, logger: Logger? = nil) -> RpcBlockchain {
        let blockchain = RpcBlockchain(address: address, storage: storage, syncer: syncer, transactionBuilder: transactionBuilder, logger: logger)
        syncer.delegate = blockchain
        return blockchain
    }

}

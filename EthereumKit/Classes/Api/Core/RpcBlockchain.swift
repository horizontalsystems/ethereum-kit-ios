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

    func didUpdate(state: AccountState) {
        storage.save(accountState: state)
        delegate?.onUpdate(accountState: state)
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

    var accountState: AccountState? {
        storage.accountState
    }

    func nonceSingle(defaultBlockParameter: DefaultBlockParameter) -> Single<Int> {
        syncer.single(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: defaultBlockParameter))
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

    func transactionReceiptSingle(transactionHash: Data) -> Single<RpcTransactionReceipt?> {
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

    func getBlock(blockNumber: Int) -> Single<RpcBlock?> {
        syncer.single(rpc: GetBlockByNumberJsonRpc(number: blockNumber))
    }

}

extension RpcBlockchain {

    static func instance(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionSigner: TransactionSigner, transactionBuilder: TransactionBuilder, logger: Logger? = nil) -> RpcBlockchain {
        let blockchain = RpcBlockchain(address: address, storage: storage, syncer: syncer, transactionSigner: transactionSigner, transactionBuilder: transactionBuilder, logger: logger)
        syncer.delegate = blockchain
        return blockchain
    }

}

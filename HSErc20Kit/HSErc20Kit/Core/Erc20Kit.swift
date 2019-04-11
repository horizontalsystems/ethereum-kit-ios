import RxSwift
import HSEthereumKit
import HSCryptoKit

public class Erc20Kit {
    static let transferEventTopic = Data(hex: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef")! // Keccak-256("Transfer(address,address,uint256)")

    let disposeBag = DisposeBag()
    let queue: DispatchQueue

    let ethereumKit: EthereumKit
    let storage: GrdbStorage
    let transactionSyncer: TransactionSyncer
    let balanceSyncer: BalanceSyncer
    let transactionBuilder: TransactionBuilder
    let address: Data
    var tokens = [Data: Token]()
    var delegates = [Data: IErc20TokenDelegate]()

    init(ethereumKit: EthereumKit, storage: GrdbStorage, queue: DispatchQueue = DispatchQueue(label: "syncQueue", qos: .background)) {
        self.ethereumKit = ethereumKit
        self.storage = storage
        self.address = Data(hex: ethereumKit.receiveAddress)!
        self.queue = queue
        self.transactionSyncer = TransactionSyncer(storage: storage, addressTopic: Data(repeating: 0, count: 12) + self.address)
        self.balanceSyncer = BalanceSyncer(storage: storage)
        self.transactionBuilder = TransactionBuilder()

        self.transactionSyncer.delegate = self
        self.balanceSyncer.delegate = self
    }

    private func sync() {
        queue.async {
            guard let blockNumber = self.ethereumKit.lastBlockHeight else {
                return
            }

            self.transactionSyncer.sync(forBlock: blockNumber)
            self.balanceSyncer.sync(forBlock: blockNumber)
        }
    }

    func send(request: IRequest) {
        ethereumKit.send(request: request, by: self)
    }

}

extension Erc20Kit {

    public func syncState(contractAddress: Data) -> EthereumKit.SyncState {
        guard let balanceState = balanceSyncer.tokenStates[contractAddress] else {
            return .notSynced
        }

        let resolvedState: EthereumKit.SyncState!

        if balanceState == .synced && transactionSyncer.syncState == .synced {
            resolvedState = .synced
        } else if balanceState == .notSynced || transactionSyncer.syncState == .notSynced {
            resolvedState = .notSynced
        } else {
            resolvedState = .syncing
        }

        return resolvedState
    }

    public func balance(contractAddress: Data) -> String? {
        return tokens[contractAddress]?.balance?.asString(withBase: 10)
    }

    public func sendSingle(contractAddress: Data, to: String, value: String, gasPrice: Int) -> Single<HSErc20Kit.TransactionInfo> {
        guard let toData = Data(hex: to) else {
            return Single.error(EthereumKit.SendError.invalidValue)
        }

        guard let valueBInt = BInt(value, radix: 16) else {
            return Single.error(EthereumKit.SendError.invalidValue)
        }

        let transactionInput = transactionBuilder.transferTransactionInput(to: toData, value: valueBInt)

        return ethereumKit.sendSingle(to: contractAddress, value: BInt(0).asString(withBase: 10), transactionInput: transactionInput, gasPrice: gasPrice)
                .map({ Transaction(transactionHash: Data(hex: $0.hash)!, contractAddress: contractAddress, from: self.address, to: toData, value: valueBInt) })
                .do(onSuccess: { [weak self] transaction in
                    self?.storage.save(transactions: [transaction])
                })
                .map({ TransactionInfo(transaction: $0) })
    }

    public func transactionsSingle(contractAddress: Data, hashFrom: Data?, indexFrom: Int?, limit: Int?) -> Single<[TransactionInfo]> {
        return storage.transactionsSingle(contractAddress: contractAddress, hashFrom: hashFrom, indexFrom: indexFrom, limit: limit).map {
            $0.map {
                TransactionInfo(transaction: $0)
            }
        }
    }

    public func register(contractAddress: Data, position: Int64, decimal: Int, delegate: IErc20TokenDelegate) {
        var positionKeyData = Data(repeating: 0, count: 12) + address
        positionKeyData += Data(repeating: 0, count: 24) + Data(withUnsafeBytes(of: position) {
            Data($0)
        }).reversed()

        let token = storage.token(contractAddress: contractAddress) ?? Token(contractAddress: contractAddress, contractBalanceKey: CryptoKit.sha3(positionKeyData).toHexString(), balance: nil, syncedBlockHeight: nil)

        tokens[contractAddress] = token
        delegates[contractAddress] = delegate
    }

}

extension Erc20Kit: IEthereumKitDelegate {

    public func onStart() {
        sync()
    }

    public func onUpdateLastBlockHeight() {
        sync()
    }

    public func onClear() {
        tokens.removeAll()
        delegates.removeAll()
        storage.clear()
    }

    public func onResponse(response: IResponse) {
        switch response {
        case let response as GetLogsResponse: transactionSyncer.handle(response: response)
        case let response as GetStorageAtResponse: balanceSyncer.handle(response: response)
        default: ()
        }

        sync()
    }

}

extension Erc20Kit: ITransactionSyncerDelegate {

    func onSyncStateUpdated(state: EthereumKit.SyncState) {
        for (_, delegate) in delegates {
            delegate.onUpdateSyncState()
        }
    }

}

extension Erc20Kit: IBalanceSyncerDelegate {

    func onSyncStateUpdated(contractAddress: Data, state: EthereumKit.SyncState) {
        if let delegate = delegates[contractAddress] {
            delegate.onUpdateSyncState()
        }
    }

    func onBalanceUpdated(contractAddress: Data) {
        if let delegate = delegates[contractAddress] {
            delegate.onUpdateBalance()
        }
    }

}


extension Erc20Kit {

    public static func instance(ethereumKit: EthereumKit, networkType: EthereumKit.NetworkType, etherscanApiKey: String, minLogLevel: Logger.Level = .verbose) -> Erc20Kit {
        let storage = GrdbStorage(databaseFileName: "erc20_tokens_db")
        let erc20Kit = Erc20Kit(ethereumKit: ethereumKit, storage: storage)
        ethereumKit.add(delegate: erc20Kit)

        return erc20Kit
    }

}


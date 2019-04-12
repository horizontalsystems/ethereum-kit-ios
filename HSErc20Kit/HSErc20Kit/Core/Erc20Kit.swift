import RxSwift
import HSEthereumKit
import HSCryptoKit

public class Erc20Kit {
    static let transferEventTopic = Data(hex: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef")! // Keccak-256("Transfer(address,address,uint256)")

    let disposeBag = DisposeBag()

    let ethereumKit: EthereumKit
    let address: Data
    let storage: GrdbStorage
    let transactionBuilder: ITransactionBuilder
    let transactionSyncer: ITransactionSyncer
    let balanceSyncer: IBalanceSyncer
    let tokensHolder: ITokensHolder
    let tokenStates: ITokenStates
    var delegates = [Data: IErc20TokenDelegate]()

    init(ethereumKit: EthereumKit, address: Data, storage: GrdbStorage, transactionBuilder: ITransactionBuilder, transactionSyncer: ITransactionSyncer, balanceSyncer: IBalanceSyncer,
         tokensHolder: ITokensHolder, tokenStates: ITokenStates) {
        self.ethereumKit = ethereumKit
        self.storage = storage
        self.address = address
        self.transactionBuilder = transactionBuilder
        self.transactionSyncer = transactionSyncer
        self.balanceSyncer = balanceSyncer
        self.tokensHolder = tokensHolder
        self.tokenStates = tokenStates
    }

    private func startTransactionsSync() {
        guard ethereumKit.syncState == .synced, let blockNumber = self.ethereumKit.lastBlockHeight else {
            return
        }

        self.transactionSyncer.sync(forBlock: blockNumber)
    }

}

extension Erc20Kit {

    public func syncState(contractAddress: Data) -> SyncState {
        return tokenStates.state(of: contractAddress)
    }

    public func balance(contractAddress: Data) -> String? {
        return tokensHolder.token(byContractAddress: contractAddress)?.balance?.asString(withBase: 10)
    }

    public func sendSingle(contractAddress: Data, to: String, value: String, gasPrice: Int) -> Single<HSErc20Kit.TransactionInfo> {
        guard let toData = Data(hex: to) else {
            return Single.error(SendError.invalidValue)
        }

        guard let valueBInt = BInt(value, radix: 16) else {
            return Single.error(SendError.invalidValue)
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

        tokensHolder.add(token: token)
        delegates[contractAddress] = delegate
    }

}

extension Erc20Kit: IEthereumKitDelegate {

    public func onUpdateSyncState() {
        startTransactionsSync()
    }

    public func onUpdateLastBlockHeight() {
        startTransactionsSync()
    }

    public func onClear() {
        tokensHolder.clear()
        tokenStates.clear()
        storage.clear()
        delegates.removeAll()
    }

}

extension Erc20Kit: ITransactionSyncerDelegate {

    func onTransactionsUpdated(contractAddress: Data, transactions: [Transaction], blockNumber: Int) {
        guard let token = tokensHolder.token(byContractAddress: contractAddress) else {
            return
        }

        if transactions.isEmpty {
            balanceSyncer.setSynced(forBlock: blockNumber, token: token)
        } else {
            delegates[contractAddress]?.onUpdate(transactions: transactions.map { TransactionInfo(transaction: $0) })

            balanceSyncer.sync(forBlock: blockNumber, token: token)
        }
    }

}

extension Erc20Kit: IBalanceSyncerDelegate {

    func onBalanceUpdated(contractAddress: Data) {
        delegates[contractAddress]?.onUpdateBalance()

        startTransactionsSync()
    }

}

extension Erc20Kit: ITokenStatesDelegate {

    func onSyncStateUpdated(contractAddress: Data) {
        delegates[contractAddress]?.onUpdateSyncState()
    }

}


extension Erc20Kit {

    public static func instance(ethereumKit: EthereumKit, networkType: EthereumKit.NetworkType, etherscanApiKey: String, minLogLevel: Logger.Level = .verbose) -> Erc20Kit {
        let address = Data(hex: ethereumKit.receiveAddress)!

        let storage = GrdbStorage(databaseFileName: "erc20_tokens_db")
        let tokensHolder = TokensHolder()
        let tokenStates = TokenStates()
        let dataProvider = DataProvider(ethereumKit: ethereumKit, addressTopic: Data(repeating: 0, count: 12) + address)
        let transactionSyncer = TransactionSyncer(storage: storage, tokensHolder: tokensHolder, tokenStates: tokenStates, dataProvider: dataProvider)
        let balanceSyncer = BalanceSyncer(storage: storage, tokenStates: tokenStates, dataProvider: dataProvider)
        let transactionBuilder = TransactionBuilder()

        let erc20Kit = Erc20Kit(
                ethereumKit: ethereumKit, address: address, storage: storage,
                transactionBuilder: transactionBuilder, transactionSyncer: transactionSyncer, balanceSyncer: balanceSyncer,
                tokensHolder: tokensHolder,
                tokenStates: tokenStates
        )

        transactionSyncer.delegate = erc20Kit
        balanceSyncer.delegate = erc20Kit
        tokenStates.delegate = erc20Kit

        ethereumKit.add(delegate: erc20Kit)

        return erc20Kit
    }

}

extension Erc20Kit {

    public enum SendError: Error {
        case invalidAddress
        case invalidContractAddress
        case invalidValue
    }

    public enum SyncState: Int {
        case notSynced = 0
        case syncing = 1
        case synced = 2
    }

}

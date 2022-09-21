import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let evmKit: EthereumKit.Kit
    private let balanceManager: BalanceManager
    private let balanceSyncManager: BalanceSyncManager
    private let transactionManager: TransactionManager
    private let storage: Storage
    private let disposeBag = DisposeBag()

    init(evmKit: EthereumKit.Kit, balanceManager: BalanceManager, balanceSyncManager: BalanceSyncManager, transactionManager: TransactionManager, storage: Storage) {
        self.evmKit = evmKit
        self.balanceManager = balanceManager
        self.balanceSyncManager = balanceSyncManager
        self.transactionManager = transactionManager
        self.storage = storage

        evmKit.syncStateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateSyncState(syncState: $0)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateSyncState(syncState: EthereumKit.SyncState) {
        switch syncState {
        case .synced:
            balanceSyncManager.sync()
        case .syncing:
            ()
        case .notSynced(let error):
            ()
        }
    }

}

extension Kit {

    public func sync() {
        if case .synced = evmKit.syncState {
            balanceSyncManager.sync()
        }
    }

    public var nftBalances: [NftBalance] {
        balanceManager.nftBalances
    }

    public var nftBalancesObservable: Observable<[NftBalance]> {
        balanceManager.nftBalancesObservable
    }

    public func nftBalance(contractAddress: Address, tokenId: BigUInt) -> NftBalance? {
        balanceManager.nftBalance(contractAddress: contractAddress, tokenId: tokenId)
    }

    public func transferEip721TransactionData(contractAddress: Address, to: Address, tokenId: BigUInt) -> TransactionData {
        transactionManager.transferEip721TransactionData(contractAddress: contractAddress, to: to, tokenId: tokenId)
    }

    public func transferEip1155TransactionData(contractAddress: Address, to: Address, tokenId: BigUInt, value: BigUInt) -> TransactionData {
        transactionManager.transferEip1155TransactionData(contractAddress: contractAddress, to: to, tokenId: tokenId, value: value)
    }

}

extension Kit: ITransactionSyncerDelegate {

    func didSync(nfts: [Nft], type: NftType) {
        balanceManager.didSync(nfts: nfts, type: type)
    }

}

extension Kit {

    public func addEip721TransactionSyncer() {
        let syncer = Eip721TransactionSyncer(provider: evmKit.transactionProvider, storage: storage)
        syncer.delegate = self
        evmKit.add(transactionSyncer: syncer)
    }

    public func addEip1155TransactionSyncer() {
        let syncer = Eip1155TransactionSyncer(provider: evmKit.transactionProvider, storage: storage)
        syncer.delegate = self
        evmKit.add(transactionSyncer: syncer)
    }

    public func addEip721Decorators() {
        evmKit.add(methodDecorator: Eip721MethodDecorator(contractMethodFactories: Eip721ContractMethodFactories.shared))
        evmKit.add(eventDecorator: Eip721EventDecorator(userAddress: evmKit.address, storage: storage))
        evmKit.add(transactionDecorator: Eip721TransactionDecorator(userAddress: evmKit.address))
    }

    public func addEip1155Decorators() {
        evmKit.add(methodDecorator: Eip1155MethodDecorator(contractMethodFactories: Eip1155ContractMethodFactories.shared))
        evmKit.add(eventDecorator: Eip1155EventDecorator(userAddress: evmKit.address, storage: storage))
        evmKit.add(transactionDecorator: Eip1155TransactionDecorator(userAddress: evmKit.address))
    }

}

extension Kit {

    public static func instance(evmKit: EthereumKit.Kit) throws -> Kit {
        let storage = Storage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "storage-\(evmKit.uniqueId)")

        let dataProvider = DataProvider(evmKit: evmKit)
        let balanceSyncManager = BalanceSyncManager(address: evmKit.address, storage: storage, dataProvider: dataProvider)
        let balanceManager = BalanceManager(storage: storage, syncManager: balanceSyncManager)

        balanceSyncManager.delegate = balanceManager

        let transactionManager = TransactionManager(evmKit: evmKit)

        let kit = Kit(
                evmKit: evmKit,
                balanceManager: balanceManager,
                balanceSyncManager: balanceSyncManager,
                transactionManager: transactionManager,
                storage: storage
        )

        return kit
    }

    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("nft-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

}

import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let evmKit: EthereumKit.Kit
    let balanceManager: BalanceManager
    private let balanceSyncManager: BalanceSyncManager
    let storage: Storage
    private let disposeBag = DisposeBag()

    init(evmKit: EthereumKit.Kit, balanceManager: BalanceManager, balanceSyncManager: BalanceSyncManager, storage: Storage) {
        self.evmKit = evmKit
        self.balanceManager = balanceManager
        self.balanceSyncManager = balanceSyncManager
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

    public func start() {
        if case .synced = evmKit.syncState {
            balanceSyncManager.sync()
        }
    }

    public func stop() {
    }

    public func refresh() {
    }

    public var nftBalances: [NftBalance] {
        balanceManager.nftBalances
    }

    public var nftBalancesObservable: Observable<[NftBalance]> {
        balanceManager.nftBalancesObservable
    }

}

extension Kit: ITransactionSyncerDelegate {

    func didSync(nfts: [Nft], type: NftType) {
        balanceManager.didSync(nfts: nfts, type: type)
    }

}

extension Kit {

    public static func instance(evmKit: EthereumKit.Kit) throws -> Kit {
        let storage = Storage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "storage-\(evmKit.uniqueId)")

        let dataProvider = DataProvider(evmKit: evmKit)
        let balanceSyncManager = BalanceSyncManager(address: evmKit.address, storage: storage, dataProvider: dataProvider)
        let balanceManager = BalanceManager(storage: storage, syncManager: balanceSyncManager)

        balanceSyncManager.delegate = balanceManager

        let kit = Kit(
                evmKit: evmKit,
                balanceManager: balanceManager,
                balanceSyncManager: balanceSyncManager,
                storage: storage
        )

        return kit
    }

    public static func addTransactionSyncers(nftKit: Kit, evmKit: EthereumKit.Kit) {
        let eip721Syncer = Eip721TransactionSyncer(provider: evmKit.transactionProvider, storage: nftKit.storage)
        let eip1155Syncer = Eip1155TransactionSyncer(provider: evmKit.transactionProvider, storage: nftKit.storage)

        eip721Syncer.delegate = nftKit
        eip1155Syncer.delegate = nftKit

        evmKit.add(transactionSyncer: eip721Syncer)
        evmKit.add(transactionSyncer: eip1155Syncer)
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

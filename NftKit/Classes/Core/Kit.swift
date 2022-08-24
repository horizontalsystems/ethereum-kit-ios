import RxSwift
import EthereumKit
import BigInt

public class Kit {
    private let disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit

    init(evmKit: EthereumKit.Kit) {
        self.evmKit = evmKit

        evmKit.syncStateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateSyncState(syncState: $0)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateSyncState(syncState: EthereumKit.SyncState) {
    }

}

extension Kit {

    public func start() {
    }

    public func stop() {
    }

    public func refresh() {
    }

}

extension Kit {

    public static func instance(evmKit: EthereumKit.Kit) throws -> Kit {
        let storage = Storage(databaseDirectoryUrl: try dataDirectoryUrl(), databaseFileName: "storage-\(evmKit.uniqueId)")

        let kit = Kit(evmKit: evmKit)

        let eip721Syncer = Eip721TransactionSyncer(provider: evmKit.transactionProvider, storage: storage)
        evmKit.add(transactionSyncer: eip721Syncer)

        let eip1155Syncer = Eip1155TransactionSyncer(provider: evmKit.transactionProvider, storage: storage)
        evmKit.add(transactionSyncer: eip1155Syncer)

        return kit
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

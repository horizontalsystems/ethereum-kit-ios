import RxSwift
import BigInt
import EthereumKit

class BalanceManager {
    private let storage: Storage
    private let syncManager: BalanceSyncManager

    private let nftBalancesSubject = PublishSubject<[NftBalance]>()
    private(set) var nftBalances: [NftBalance] = [] {
        didSet {
            nftBalancesSubject.onNext(nftBalances)
        }
    }

    init(storage: Storage, syncManager: BalanceSyncManager) {
        self.storage = storage
        self.syncManager = syncManager

        syncNftBalances()
    }

    private func syncNftBalances() {
        do {
            nftBalances = try storage.existingNftBalances()
        } catch {
            // todo
        }
    }

    private func handleNftsFromTransactions(type: NftType, nfts: [Nft]) throws {
        let existingBalances = try storage.nftBalances(type: type)

        let existingNfts = existingBalances.map { $0.nft }
        let newNfts = nfts.filter { !existingNfts.contains($0) }

        try storage.setNotSynced(nfts: existingNfts)
        try storage.save(nftBalances: newNfts.map { NftBalance(nft: $0, balance: 0, synced: false) })

        syncManager.sync()
    }

}

extension BalanceManager {

    var nftBalancesObservable: Observable<[NftBalance]> {
        nftBalancesSubject.asObservable()
    }

    func nftBalance(contractAddress: Address, tokenId: BigUInt) -> NftBalance? {
        try? storage.existingNftBalance(contractAddress: contractAddress, tokenId: tokenId)
    }

    func didSync(nfts: [Nft], type: NftType) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            try? self?.handleNftsFromTransactions(type: type, nfts: nfts)
        }
    }

}

extension BalanceManager: IBalanceSyncManagerDelegate {

    func didFinishSyncBalances() {
        syncNftBalances()
    }

}

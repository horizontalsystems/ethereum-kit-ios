import RxSwift
import BigInt
import EthereumKit

class BalanceSyncManager {
    private let address: Address
    private let storage: Storage
    private let dataProvider: DataProvider
    private let disposeBag = DisposeBag()

    private var syncing = false
    private var syncRequested = false

    private let queue = DispatchQueue(label: "io.horizontal-systems.nft-kit.balance-sync-manager", qos: .utility)

    weak var delegate: IBalanceSyncManagerDelegate?

    init(address: Address, storage: Storage, dataProvider: DataProvider) {
        self.address = address
        self.storage = storage
        self.dataProvider = dataProvider
    }

    private func _finishSync() {
        syncing = false

        if syncRequested {
            syncRequested = false
            try? sync()
        }
    }

    private func _handle(nftBalances: [NftBalance], balances: [Int?]) {
        var balanceInfos = [(Nft, Int)]()

        for (index, nftBalance) in nftBalances.enumerated() {
            let balance = balances[index]

            if let balance = balance {
//                print("Synced balance for \(nftBalance.nft.tokenName) - \(nftBalance.nft.contractAddress) - \(nftBalance.nft.tokenId) - \(balance)")
                balanceInfos.append((nftBalance.nft, balance))
            } else {
                print("Failed to sync balance for \(nftBalance.nft.tokenName) - \(nftBalance.nft.contractAddress) - \(nftBalance.nft.tokenId)")
            }
        }

        try? storage.setSynced(balanceInfos: balanceInfos)

        delegate?.didFinishSyncBalances()

        _finishSync()
    }

    private func handle(nftBalances: [NftBalance], balances: [Int?]) {
        queue.async {
            self._handle(nftBalances: nftBalances, balances: balances)
        }
    }

    private func _sync() throws {
        if syncing {
            syncRequested = true
            return
        }

        syncing = true

        let nftBalances = try storage.nonSyncedNftBalances()

        guard !nftBalances.isEmpty else {
            _finishSync()
            return
        }

//        print("NON SYNCED: \(nftBalances.count)")

        let singles: [Single<Int?>] = nftBalances.map { nftBalance in
            balanceSingle(nft: nftBalance.nft)
                    .map { balance -> Int? in balance }
                    .catchErrorJustReturn(nil)
        }

        Single.zip(singles)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] balances in
                    self?.handle(nftBalances: nftBalances, balances: balances)
                })
                .disposed(by: disposeBag)
    }

    private func balanceSingle(nft: Nft) -> Single<Int> {
        let address = address

        switch nft.type {
        case .eip721:
            return dataProvider.getEip721Owner(contractAddress: nft.contractAddress, tokenId: nft.tokenId)
                    .map { owner in
                        owner == address ? 1 : 0
                    }
                    .catchError { error in
                        if let responseError = error as? JsonRpcResponse.ResponseError, case .rpcError = responseError {
                            return Single.just(0)
                        }

                        return Single.error(error)
                    }

        case .eip1155:
            return dataProvider.getEip1155Balance(contractAddress: nft.contractAddress, owner: address, tokenId: nft.tokenId)
        }
    }

}

extension BalanceSyncManager {

    func sync() {
        queue.async {
            try? self._sync()
        }
    }

}

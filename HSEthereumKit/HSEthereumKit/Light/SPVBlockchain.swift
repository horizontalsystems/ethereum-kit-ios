import Foundation
import RxSwift
import HSHDWalletKit

class SPVBlockchain {
    var ethereumAddress: String = ""
    var gasPriceInWei: Int = 0
    var gasLimitEthereum: Int = 0
    var gasLimitErc20: Int = 0
    var syncState: EthereumKit.SyncState = .synced
    weak var delegate: IBlockchainDelegate?

    var peerGroup: IPeerGroup
    let reachabilityManager: ReachabilityManager
    let storage: IStorage

    init(storage: IStorage, words: [String], debugPrints: Bool = false) {
        let hdWallet = try! Wallet(seed: Mnemonic.seed(mnemonic: words), network: Network.ropsten, debugPrints: debugPrints)
        ethereumAddress = hdWallet.address()

        peerGroup = PeerGroup(network: Ropsten(), address: ethereumAddress)
        reachabilityManager = ReachabilityManager()
        self.storage = storage

        peerGroup.delegate = self
    }

}

extension SPVBlockchain: IBlockchain {

    func start() {
        peerGroup.start()
    }

    func clear() {
    }

    func syncState(contractAddress: String) -> EthereumKit.SyncState {
        return EthereumKit.SyncState.synced
    }

    func register(contractAddress: String) {
    }

    func unregister(contractAddress: String) {
    }

    func sendSingle(to address: String, amount: String, gasPriceInWei: Int?) -> Single<EthereumTransaction> {
        let stubTransaction = EthereumTransaction(hash: "", nonce: 0, from: "", to: "", amount: "", gasLimit: 0, gasPriceInWei: 0)
        return Single.just(stubTransaction)
    }

    func sendErc20Single(to address: String, contractAddress: String, amount: String, gasPriceInWei: Int?) -> Single<EthereumTransaction> {
        let stubTransaction = EthereumTransaction(hash: "", nonce: 0, from: "", to: "", amount: "", gasLimit: 0, gasPriceInWei: 0)
        return Single.just(stubTransaction)
    }
}

extension SPVBlockchain: IPeerGroupDelegate {

    func onUpdate(state: AccountState) {
        delegate?.onUpdate(balance: state.balance.wei.asString(withBase: 10))
    }

}

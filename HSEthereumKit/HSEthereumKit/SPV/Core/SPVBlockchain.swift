import Foundation
import RxSwift
import HSHDWalletKit

class SPVBlockchain {
    var ethereumAddress: String
    var gasPriceInWei: Int = 0
    var gasLimitEthereum: Int = 0
    var gasLimitErc20: Int = 0
    var syncState: EthereumKit.SyncState = .synced
    weak var delegate: IBlockchainDelegate?

    var peerGroup: IPeerGroup
    let reachabilityManager: ReachabilityManager
    let storage: ISPVStorage

    init(storage: ISPVStorage, words: [String], network: INetwork, debugPrints: Bool = false) {
        let hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), coinType: network.coinType, xPrivKey: network.privateKeyPrefix.bigEndian, xPubKey: network.publicKeyPrefix.bigEndian)

        let addressKey = try! hdWallet.privateKey(account: 0, index: 0, chain: .external)
        let publicKey = addressKey.publicKey(compressed: false).raw
        let address = EIP55.encode(CryptoUtils.shared.sha3(publicKey.dropFirst()).suffix(20))
        let addressData = Data(hex: String(address[address.index(address.startIndex, offsetBy: 2)...]))

        let connectionKey = try! hdWallet.privateKey(account: 100, index: 100, chain: .external)
        let connectionPublicKey = Data(connectionKey.publicKey(compressed: false).raw.suffix(from: 1))
        let connectionECKey = ECKey(
                privateKey: connectionKey.raw,
                publicKeyPoint: ECPoint(nodeId: connectionPublicKey)
        )

        peerGroup = PeerGroup(network: Ropsten(), storage: storage, connectionKey: connectionECKey, address: addressData)
        reachabilityManager = ReachabilityManager()
        self.ethereumAddress = address
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

import Foundation
import RxSwift
import HSHDWalletKit

class SpvBlockchain {
    weak var delegate: IBlockchainDelegate?

    private let peerGroup: IPeerGroup

    let ethereumAddress: String

    var gasPriceInWei: GasPrice = GasPrice.defaultGasPrice
    var gasLimitEthereum: Int = 0
    var gasLimitErc20: Int = 0

    private init(peerGroup: IPeerGroup, ethereumAddress: String) {
        self.peerGroup = peerGroup
        self.ethereumAddress = ethereumAddress
    }

}

extension SpvBlockchain: IBlockchain {

    func start() {
        peerGroup.start()
    }

    func clear() {
    }

    var syncState: EthereumKit.SyncState {
        return EthereumKit.SyncState.synced
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

extension SpvBlockchain: IPeerGroupDelegate {

    func onUpdate(state: AccountState) {
        delegate?.onUpdate(balance: state.balance.wei.asString(withBase: 10))
    }

}

extension SpvBlockchain {

    static func spvBlockchain(storage: ISpvStorage, words: [String], testMode: Bool, logger: Logger? = nil) -> SpvBlockchain {
        let network = Ropsten()

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

        let peerGroup = PeerGroup(network: Ropsten(), storage: storage, connectionKey: connectionECKey, address: addressData, logger: logger)

        let spvBlockchain = SpvBlockchain(peerGroup: peerGroup, ethereumAddress: address)

        peerGroup.delegate = spvBlockchain

        return spvBlockchain
    }

}

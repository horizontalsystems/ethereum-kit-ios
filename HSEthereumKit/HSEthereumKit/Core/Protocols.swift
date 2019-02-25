import Foundation
import RxSwift
import HSCryptoKit

protocol IFactory: class {
    func authMessage(signature: Data, publicKeyPoint: ECPoint, nonce: Data) -> AuthMessage
    func authAckMessage(data: Data) -> AuthAckMessage?
    func keccakDigest() -> KeccakDigest
}

protocol IECIESCrypto {
    func randomKey() -> ECKey
    func randomBytes(length: Int) -> Data
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ecdhAgree(myPrivateKey: Data, remotePublicKeyPoint: Data) -> Data
    func concatKDF(_ data: Data) -> Data
    func sha256(_ data: Data) -> Data
    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int, iv: Data) -> Data
    func hmacSha256(_ data: Data, key: Data, iv: Data, macData: Data) -> Data
}

protocol ICrypto: class {
    func randomKey() -> ECKey
    func randomBytes(length: Int) -> Data
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ellipticSign(_ messageToSign: Data, key: ECKey) throws -> Data
    func eciesDecrypt(privateKey: Data, message: ECIESEncryptedMessage) throws -> Data
    func eciesEncrypt(remotePublicKey: ECPoint, message: Data) -> ECIESEncryptedMessage
    func sha3(_ data: Data) -> Data
}

public protocol IEthereumKitDelegate: class {
    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateBalance()
    func onUpdateLastBlockHeight()
    func onUpdateSyncState()
}


protocol IPeerDelegate: class {
    func connected()
    func blocksReceived(blockHeaders: [BlockHeader])
    func proofReceived(message: ProofsMessage)
}

protocol IDevP2PPeerDelegate: class {
    func connectionEstablished()
    func connectionDidDisconnect(withError error: Error?)
    func connection(didReceiveMessage message: IMessage)
}

protocol IConnectionDelegate: class {
    func connectionEstablished()
    func connectionKey() -> ECKey
    func connectionDidDisconnect(withError error: Error?)
    func connection(didReceiveMessage message: IMessage)
}

protocol IPeer: class {
    var delegate: IPeerDelegate? { get set }
    func connect()
    func disconnect(error: Error?)
    func downloadBlocksFrom(block: BlockHeader)
    func getBalance(forAddress address: Data, inBlockWithHash blockHash: Data)
}

protocol IConnection: class {
    var delegate: IConnectionDelegate? { get set }
    var logName: String { get }
    func connect()
    func disconnect(error: Error?)
    func register(capability: Capability)
    func send(message: IMessage)
}

protocol INetwork {
    var id: Int { get }
    var genesisBlockHash: Data { get }
    var checkpointBlock: BlockHeader{ get }
}

protocol IFrameHandler {
    func register(capability: Capability)
    func addFrames(frames: [Frame])
    func getMessage() throws -> IMessage?
    func getFrames(from message: IMessage) -> [Frame]
}

protocol IMessage {
    init?(data: Data)
    func encoded() -> Data
    func toString() -> String
}

protocol IPeerGroupDelegate: class {
    func onUpdate(state: AccountState)
}

protocol IPeerGroup {
    var delegate: IPeerGroupDelegate? { get set }
    func start()
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IApiConfigProvider {
    var reachabilityHost: String { get }
    var apiUrl: String { get }
}

protocol IApiProvider {
    func getGasPriceInWei() -> Single<Int>
    func getLastBlockHeight() -> Single<Int>
    func getTransactionCount(address: String) -> Single<Int>

    func getBalance(address: String) -> Single<Decimal>
    func getBalanceErc20(address: String, contractAddress: String, decimal: Int) -> Single<Decimal>

    func getTransactions(address: String, startBlock: Int64) -> Single<[EthereumTransaction]>
    func getTransactionsErc20(address: String, startBlock: Int64, decimals: [String: Int]) -> Single<[EthereumTransaction]>

    func send(from: String, to: String, nonce: Int, amount: Decimal, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction>
    func sendErc20(contractAddress: String, decimal: Int, from: String, to: String, nonce: Int, amount: Decimal, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction>
}

protocol IPeriodicTimer {
    var delegate: IPeriodicTimerDelegate? { get set }
    func schedule()
    func invalidate()
}

protocol IPeriodicTimerDelegate: class {
    func onFire()
}

protocol IRefreshKitDelegate: class {
    func onRefresh()
    func onDisconnect()
}

protocol IRefreshManager {
    func didRefresh()
}

protocol IAddressValidator {
    func validate(address: String) throws
}

protocol IStorage {
    var lastBlockHeight: Int? { get }
    var gasPriceInWei: Int? { get }

    func balance(forAddress address: String) -> Decimal?
    func lastTransactionBlockHeight(erc20: Bool) -> Int?
    func transactionsSingle(fromHash: String?, limit: Int?, contractAddress: String?) -> Single<[EthereumTransaction]>

    func save(lastBlockHeight: Int)
    func save(gasPriceInWei: Int)
    func save(balance: Decimal, address: String)
    func save(transactions: [EthereumTransaction])

    func clear()
}

protocol IBlockchain {
    var ethereumAddress: String { get }
    var gasPriceInWei: Int { get }
    var gasLimitEthereum: Int { get }
    var gasLimitErc20: Int { get }

    var delegate: IBlockchainDelegate? { get set }

    func start()
    func clear()

    var syncState: EthereumKit.SyncState { get }
    func syncState(contractAddress: String) -> EthereumKit.SyncState

    func register(contractAddress: String, decimal: Int)
    func unregister(contractAddress: String)

    func sendSingle(to address: String, amount: Decimal, gasPriceInWei: Int?) -> Single<EthereumTransaction>
    func sendErc20Single(to address: String, contractAddress: String, amount: Decimal, gasPriceInWei: Int?) -> Single<EthereumTransaction>
}

protocol IBlockchainDelegate: class {
    func onUpdate(lastBlockHeight: Int)

    func onUpdate(balance: Decimal)
    func onUpdateErc20(balance: Decimal, contractAddress: String)

    func onUpdate(syncState: EthereumKit.SyncState)
    func onUpdateErc20(syncState: EthereumKit.SyncState, contractAddress: String)

    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateErc20(transactions: [EthereumTransaction], contractAddress: String)
}

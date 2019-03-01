import Foundation
import HSCryptoKit

protocol ISPVStorage: IStorage {
    func lastBlockHeader() -> BlockHeader?
    func save(blockHeaders: [BlockHeader])
}

protocol IRandomHelper: class {
    func randomKey() -> ECKey
    func randomBytes(length: Int) -> Data
    func randomBytes(length: Range<Int>) -> Data
}

protocol IFactory: class {
    func authMessage(signature: Data, publicKeyPoint: ECPoint, nonce: Data) -> AuthMessage
    func authAckMessage(data: Data) -> AuthAckMessage?
    func keccakDigest() -> KeccakDigest
}

protocol IFrameCodecHelper {
    func updateMac(mac: KeccakDigest, macKey: Data, data: Data) -> Data
    func toThreeBytes(int: Int) -> Data
    func fromThreeBytes(data: Data) -> Int
}

protocol IAESEncryptor {
    func encrypt(_ data: Data) -> Data
}

protocol IECIESCrypto {
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ecdhAgree(myPrivateKey: Data, remotePublicKeyPoint: Data) -> Data
    func concatKDF(_ data: Data) -> Data
    func sha256(_ data: Data) -> Data
    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int, iv: Data) -> Data
    func hmacSha256(_ data: Data, key: Data, iv: Data, macData: Data) -> Data
}

protocol ICrypto: class {
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ellipticSign(_ messageToSign: Data, key: ECKey) throws -> Data
    func eciesDecrypt(privateKey: Data, message: ECIESEncryptedMessage) throws -> Data
    func eciesEncrypt(remotePublicKey: ECPoint, message: Data) -> ECIESEncryptedMessage
    func sha3(_ data: Data) -> Data
    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int) -> Data
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
    var checkpointBlock: BlockHeader { get }
    var coinType: UInt32 { get }
    var privateKeyPrefix: UInt32 { get }
    var publicKeyPrefix: UInt32 { get }
}

protocol IFrameHandler {
    func register(capability: Capability)
    func add(frame: Frame)
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

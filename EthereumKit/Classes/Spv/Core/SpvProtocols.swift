import RxSwift
import OpenSslKit

protocol ISpvStorage {
    var lastBlockHeader: BlockHeader? { get }
    func blockHeader(height: Int) -> BlockHeader?
    func reversedLastBlockHeaders(from height: Int, limit: Int) -> [BlockHeader]
    func save(blockHeaders: [BlockHeader])

    var accountState: AccountStateSpv? { get }
    func save(accountState: AccountStateSpv)
}

protocol IRandomHelper: AnyObject {
    var randomInt: Int { get }
    func randomKey() -> ECKey
    func randomBytes(length: Int) -> Data
    func randomBytes(length: Range<Int>) -> Data
}

protocol IFactory: AnyObject {
    func authMessage(signature: Data, publicKeyPoint: ECPoint, nonce: Data) -> AuthMessage
    func authAckMessage(data: Data) throws -> AuthAckMessage
    func keccakDigest() -> KeccakDigest
    func frameCodec(secrets: Secrets) -> FrameCodec
    func encryptionHandshake(myKey: ECKey, publicKey: Data) -> EncryptionHandshake
}

protocol IFrameCodecHelper {
    func updateMac(mac: KeccakDigest, macKey: Data, data: Data) -> Data
    func toThreeBytes(int: Int) -> Data
    func fromThreeBytes(data: Data) -> Int
}

protocol IAESCipher {
    func process(_ data: Data) -> Data
}

protocol IECIESCryptoUtils {
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ecdhAgree(myPrivateKey: Data, remotePublicKeyPoint: Data) -> Data
    func concatKDF(_ data: Data) -> Data
    func sha256(_ data: Data) -> Data
    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int, iv: Data) -> Data
    func hmacSha256(_ data: Data, key: Data, iv: Data, macData: Data) -> Data
}

protocol ICryptoUtils: AnyObject {
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ellipticSign(_ messageToSign: Data, key: ECKey) throws -> Data
    func ellipticSign(_ messageToSign: Data, privateKey: Data) throws -> Data
    func eciesDecrypt(privateKey: Data, message: ECIESEncryptedMessage) throws -> Data
    func eciesEncrypt(remotePublicKey: ECPoint, message: Data) -> ECIESEncryptedMessage
    func sha3(_ data: Data) -> Data
    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int) -> Data
}

protocol IDevP2PPeerDelegate: AnyObject {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(message: IInMessage)
}

protocol IConnectionDelegate: AnyObject {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(frame: Frame)
}

protocol IPeer: ITaskPerformer {
    var id: String { get }

    var delegate: IPeerDelegate? { get set }

    func register(messageHandler: IMessageHandler)

    func connect()
//    func disconnect(error: Error?)
}

protocol ITaskPerformer: AnyObject {
    func register(taskHandler: ITaskHandler)
    func add(task: ITask)
}

protocol IPeerDelegate: AnyObject {
    func didConnect(peer: IPeer)
    func didDisconnect(peer: IPeer, error: Error?)
}

protocol IConnection: AnyObject {
    var delegate: IConnectionDelegate? { get set }

    func connect()
    func disconnect(error: Error?)
    func send(frame: Frame)

    var logName: String { get }
}

protocol IFrameConnection: AnyObject {
    var delegate: IFrameConnectionDelegate? { get set }

    func connect()
    func disconnect(error: Error?)
    func send(packetType: Int, payload: Data)

    var logName: String { get }
}

protocol IFrameConnectionDelegate: AnyObject {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(packetType: Int, payload: Data)
}

protocol IDevP2PConnection: AnyObject {
    var delegate: IDevP2PConnectionDelegate? { get set }

    func register(sharedCapabilities: [Capability])

    func connect()
    func disconnect(error: Error?)
    func send(message: IOutMessage)

    var logName: String { get }
}

protocol IDevP2PConnectionDelegate: AnyObject {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(message: IInMessage)
}

protocol INetwork {
    var chainId: Int { get }
    var genesisBlockHash: Data { get }
    var checkpointBlock: BlockHeader { get }
    var bootnodes: [String] { get }
    var blockTime: TimeInterval { get }
}

protocol IDevP2PPeer {
    func connect()
    func disconnect(error: Error?)
    func send(message: IOutMessage)

    var logName: String { get }
}

protocol IMessage {
    func toString() -> String
}

protocol IInMessage: IMessage {
    init(data: Data) throws
}

protocol IOutMessage: IMessage {
    func encoded() -> Data
}

protocol ICapabilityHelper {
    func sharedCapabilities(myCapabilities: [Capability], nodeCapabilities: [Capability]) -> [Capability]
}

protocol IPeerProvider {
    func peer() -> IPeer
}

protocol IBlockHelper {
    var lastBlockHeader: BlockHeader { get }
}

protocol ITask {
}

protocol ITaskHandler {
    func perform(task: ITask, requester: ITaskHandlerRequester) -> Bool
}

protocol IMessageHandler {
    func handle(peer: IPeer, message: IInMessage) throws -> Bool
}

protocol ITaskHandlerRequester: AnyObject {
    func send(message: IOutMessage)
}

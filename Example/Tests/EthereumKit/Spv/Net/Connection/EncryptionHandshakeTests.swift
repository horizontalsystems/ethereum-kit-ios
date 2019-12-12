import XCTest
import Cuckoo
@testable import EthereumKit

class EncryptionHandshakeTests: XCTestCase {
    private var myKey: ECKey!
    private var ephemeralKey: ECKey!
    private var remoteKeyPoint: ECPoint!
    private var remoteEphemeralKeyPoint: ECPoint!
    private var mockCrypto: MockICryptoUtils!
    private var mockRandom: MockIRandomHelper!
    private var mockFactory: MockIFactory!
    private var authMessage: AuthMessage!
    private var authAckMessage: AuthAckMessage!

    private var nonce = Data(repeating: 0, count: 32)
    private var remoteNonce = Data(repeating: 1, count: 32)
    private var junkData = Data(repeating: 2, count: 102)
    private var sharedSecret = Data(repeating: 3, count: 32)
    private var ephemeralSharedSecret = Data(repeating: 4, count: 32)
    private var signature = Data(repeating: 5, count: 32)
    private var authECIESMessage = ECIESEncryptedMessage(prefixBytes: Data(), ephemeralPublicKey: Data(), initialVector: Data(), cipher: Data(), checksum: Data())
    private var encodedAuthECIESMessage: Data!
    private var encodedAuthAckMessage: Data!

    private var encryptionHandshake: EncryptionHandshake!

    override func setUp() {
        super.setUp()

        myKey = RandomHelper.shared.randomKey()
        ephemeralKey = RandomHelper.shared.randomKey()
        remoteKeyPoint = RandomHelper.shared.randomKey().publicKeyPoint
        remoteEphemeralKeyPoint = RandomHelper.shared.randomKey().publicKeyPoint
        encodedAuthECIESMessage = authECIESMessage.encoded()

        authMessage = AuthMessage(signature: signature, publicKeyPoint: myKey.publicKeyPoint, nonce: nonce)
        encodedAuthAckMessage = RLP.encode([remoteEphemeralKeyPoint.x + remoteEphemeralKeyPoint.y, remoteNonce, 4])
        authAckMessage = try! AuthAckMessage(data: encodedAuthAckMessage)

        mockCrypto = MockICryptoUtils()
        mockRandom = MockIRandomHelper()
        mockFactory = MockIFactory()

        stub(mockRandom) { mock in
            when(mock.randomKey()).thenReturn(ephemeralKey)
            when(mock.randomBytes(length: equal(to: 32))).thenReturn(nonce)
            when(mock.randomBytes(length: equal(to: Range<Int>(uncheckedBounds: (lower: 100, upper: 300))))).thenReturn(junkData)
        }

        stub(mockCrypto) { mock in
            when(mock.ecdhAgree(myKey: equal(to: myKey), remotePublicKeyPoint: equal(to: remoteKeyPoint))).thenReturn(sharedSecret)
            when(mock.ecdhAgree(myKey: equal(to: ephemeralKey), remotePublicKeyPoint: equal(to: remoteEphemeralKeyPoint))).thenReturn(ephemeralSharedSecret)
            when(mock.ellipticSign(_: equal(to: sharedSecret.xor(with: nonce)), key: equal(to: ephemeralKey))).thenReturn(signature)
            when(mock.eciesEncrypt(remotePublicKey: equal(to: remoteKeyPoint), message: equal(to: authMessage.encoded() + junkData))).thenReturn(authECIESMessage)
            when(mock.eciesDecrypt(privateKey: equal(to: myKey.privateKey), message: any())).thenReturn(encodedAuthAckMessage)
        }

        stub(mockFactory) { mock in
            when(mock.authMessage(signature: equal(to: signature), publicKeyPoint: equal(to: myKey.publicKeyPoint), nonce: equal(to: nonce))).thenReturn(authMessage)
            when(mock.authAckMessage(data: any())).thenReturn(authAckMessage)
        }

        encryptionHandshake = EncryptionHandshake(myKey: myKey, publicKeyPoint: remoteKeyPoint, crypto: mockCrypto, randomHelper: mockRandom, factory: mockFactory)
        verify(mockRandom).randomKey()
        verify(mockRandom).randomBytes(length: equal(to: 32))
    }
    
    override func tearDown() {
        myKey = nil
        ephemeralKey = nil
        remoteKeyPoint = nil
        remoteEphemeralKeyPoint = nil
        encryptionHandshake = nil
        mockCrypto = nil
        mockRandom = nil
        mockFactory = nil
        authMessage = nil
        authAckMessage = nil

        super.tearDown()
    }
    
    func testCreateAuthMessage() {
        let authMessagePacket: Data!
        do {
            authMessagePacket = try encryptionHandshake.createAuthMessage()
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        verify(mockCrypto).ecdhAgree(myKey: equal(to: myKey), remotePublicKeyPoint: equal(to: remoteKeyPoint))
        verify(mockCrypto).ellipticSign(_: equal(to: sharedSecret.xor(with: nonce)), key: equal(to: ephemeralKey))
        verify(mockRandom).randomBytes(length: equal(to: Range<Int>(uncheckedBounds: (lower: 100, upper: 300))))
        verify(mockCrypto).eciesEncrypt(remotePublicKey: equal(to: remoteKeyPoint), message: equal(to: authMessage.encoded() + junkData))
        verify(mockFactory).authMessage(signature: equal(to: signature), publicKeyPoint: equal(to: myKey.publicKeyPoint), nonce: equal(to: nonce))

        verifyNoMoreInteractions(mockCrypto)
        verifyNoMoreInteractions(mockFactory)

        XCTAssertEqual(authMessagePacket, encodedAuthECIESMessage)
    }

    func testExtractSecrets() {
        let noncesHash = Data(repeating: 7, count: 32)
        let sharedSecret = Data(repeating: 8, count: 32)
        let aes = Data(repeating: 9, count: 32)
        let mac = Data(repeating: 10, count: 32)
        let token = Data(repeating: 11, count: 32)
        let egressMac = KeccakDigest()
        let ingressMac = KeccakDigest()
        let eciesMessage = ECIESEncryptedMessage(prefixBytes: Data(), ephemeralPublicKey: Data(), initialVector: Data(), cipher: Data(), checksum: Data())

        stub(mockCrypto) { mock in
            when(mock.sha3(_: equal(to: remoteNonce + nonce))).thenReturn(noncesHash)
            when(mock.sha3(_: equal(to: ephemeralSharedSecret + noncesHash))).thenReturn(sharedSecret)
            when(mock.sha3(_: equal(to: ephemeralSharedSecret + sharedSecret))).thenReturn(aes)
            when(mock.sha3(_: equal(to: ephemeralSharedSecret + aes))).thenReturn(mac)
            when(mock.sha3(_: equal(to: sharedSecret))).thenReturn(token)
        }

        stub(mockFactory) { mock in
            when(mock.keccakDigest()).thenReturn(egressMac, ingressMac)
        }

        let secrets: Secrets!
        do {
            secrets = try encryptionHandshake.extractSecrets(from: eciesMessage)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        verify(mockCrypto).eciesDecrypt(privateKey: equal(to: myKey.privateKey), message: equal(to: eciesMessage))
        verify(mockCrypto).ecdhAgree(myKey: equal(to: ephemeralKey), remotePublicKeyPoint: equal(to: remoteEphemeralKeyPoint))
        verify(mockCrypto).sha3(_: equal(to: remoteNonce + nonce))
        verify(mockCrypto).sha3(_: equal(to: ephemeralSharedSecret + noncesHash))
        verify(mockCrypto).sha3(_: equal(to: ephemeralSharedSecret + sharedSecret))
        verify(mockCrypto).sha3(_: equal(to: ephemeralSharedSecret + aes))
        verify(mockCrypto).sha3(_: equal(to: sharedSecret))
        verify(mockFactory).authAckMessage(data: equal(to: encodedAuthAckMessage))
        verify(mockFactory, times(2)).keccakDigest()

        verifyNoMoreInteractions(mockCrypto)
        verifyNoMoreInteractions(mockFactory)

        XCTAssertEqual(secrets.egressMac, egressMac)
        XCTAssertEqual(secrets.ingressMac, ingressMac)
        XCTAssertEqual(secrets.aes, aes)
        XCTAssertEqual(secrets.mac, mac)
        XCTAssertEqual(secrets.token, token)

        XCTAssertEqual(secrets.egressMac.digest(), keccakDigest(updatedWith: [mac.xor(with: remoteNonce), Data()]))
        XCTAssertEqual(secrets.ingressMac.digest(), keccakDigest(updatedWith: [mac.xor(with: nonce), Data()]))
    }

    func testExtractSecrets_NonDecodableMessage() {
        let eciesMessage = ECIESEncryptedMessage(prefixBytes: Data(), ephemeralPublicKey: Data(), initialVector: Data(), cipher: Data(), checksum: Data())
        stub(mockFactory) { mock in
            when(mock.authAckMessage(data: any())).thenThrow(MessageDecodeError.notEnoughFields)
        }

        do {
            _ = try encryptionHandshake.extractSecrets(from: eciesMessage)
            XCTFail("Expecting error")
        } catch let error as MessageDecodeError {
            XCTAssertEqual(error, MessageDecodeError.notEnoughFields)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    private func keccakDigest(updatedWith: [Data]) -> Data {
        let digest = KeccakDigest()

        for data in updatedWith {
            digest.update(with: data)
        }

        return digest.digest()
    }
    
}

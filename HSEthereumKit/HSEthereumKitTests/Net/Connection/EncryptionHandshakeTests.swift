import XCTest
import RxSwift
import Cuckoo
import HSCryptoKit
@testable import HSEthereumKit

class EncryptionHandshakeTests: XCTestCase {
    private var myKey: ECKey!
    private var ephemeralKey: ECKey!
    private var remoteKeyPoint: ECPoint!
    private var remoteEphemeralKeyPoint: ECPoint!
    private var mockCrypto: MockICrypto!
    private var mockFactory: MockIFactory!
    private var authMessage: AuthMessage!
    private var authAckMessage: AuthAckMessage!

    private var nonce = Data(repeating: 0, count: 32)
    private var remoteNonce = Data(repeating: 1, count: 32)
    private var junkData = Data(repeating: 2, count: 102)
    private var sharedSecret = Data(repeating: 3, count: 32)
    private var ephemeralSharedSecret = Data(repeating: 4, count: 32)
    private var signature = Data(repeating: 5, count: 32)
    private var encryptedAuthMessage = Data(repeating: 6, count: 200)
    private var decryptedAuthAckMessage: Data!

    private var encryptionHandshake: EncryptionHandshake!

    override func setUp() {
        super.setUp()

        myKey = ECKey.randomKey()
        ephemeralKey = ECKey.randomKey()
        remoteKeyPoint = ECKey.randomKey().publicKeyPoint
        remoteEphemeralKeyPoint = ECKey.randomKey().publicKeyPoint

        authMessage = AuthMessage(signature: signature, publicKeyPoint: myKey.publicKeyPoint, nonce: nonce)
        decryptedAuthAckMessage = RLP.encode([remoteEphemeralKeyPoint.x + remoteEphemeralKeyPoint.y, remoteNonce, 4])
        authAckMessage = AuthAckMessage(data: decryptedAuthAckMessage)!

        mockCrypto = MockICrypto()
        mockFactory = MockIFactory()

        stub(mockCrypto) { mock in
            when(mock.randomKey()).thenReturn(ephemeralKey)
            when(mock.randomBytes(length: equal(to: 32))).thenReturn(nonce)
            when(mock.randomBytes(length: equal(to: 100, equalWhen: { $0 <= $1 }))).thenReturn(junkData)
            when(mock.ecdhAgree(myKey: equal(to: myKey), remotePublicKeyPoint: equal(to: remoteKeyPoint))).thenReturn(sharedSecret)
            when(mock.ecdhAgree(myKey: equal(to: ephemeralKey), remotePublicKeyPoint: equal(to: remoteEphemeralKeyPoint))).thenReturn(ephemeralSharedSecret)
            when(mock.ellipticSign(_: equal(to: sharedSecret.xor(with: nonce)), key: equal(to: ephemeralKey))).thenReturn(signature)
            when(mock.eciesEncrypt(remotePublicKey: equal(to: remoteKeyPoint), message: equal(to: authMessage.encoded() + junkData))).thenReturn(encryptedAuthMessage)
            when(mock.eciesDecrypt(privateKey: equal(to: myKey.privateKey), message: any())).thenReturn(decryptedAuthAckMessage)
        }

        stub(mockFactory) { mock in
            when(mock.authMessage(signature: equal(to: signature), publicKeyPoint: equal(to: myKey.publicKeyPoint), nonce: equal(to: nonce))).thenReturn(authMessage)
            when(mock.authAckMessage(data: any())).thenReturn(authAckMessage)
        }

        encryptionHandshake = EncryptionHandshake(myKey: myKey, publicKeyPoint: remoteKeyPoint, crypto: mockCrypto, factory: mockFactory)
        verify(mockCrypto).randomKey()
        verify(mockCrypto).randomBytes(length: equal(to: 32))
    }
    
    override func tearDown() {
        myKey = nil
        ephemeralKey = nil
        remoteKeyPoint = nil
        remoteEphemeralKeyPoint = nil
        encryptionHandshake = nil
        mockCrypto = nil
        mockFactory = nil
        authMessage = nil
        authAckMessage = nil

        super.tearDown()
    }
    
    func testCreateAuthMessage() {
        do {
            try encryptionHandshake.createAuthMessage()
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        verify(mockCrypto).ecdhAgree(myKey: equal(to: myKey), remotePublicKeyPoint: equal(to: remoteKeyPoint))
        verify(mockCrypto).ellipticSign(_: equal(to: sharedSecret.xor(with: nonce)), key: equal(to: ephemeralKey))
        verify(mockCrypto).randomBytes(length: equal(to: 100, equalWhen: { $0 <= $1 }))
        verify(mockCrypto).eciesEncrypt(remotePublicKey: equal(to: remoteKeyPoint), message: equal(to: authMessage.encoded() + junkData))
        verify(mockFactory).authMessage(signature: equal(to: signature), publicKeyPoint: equal(to: myKey.publicKeyPoint), nonce: equal(to: nonce))

        verifyNoMoreInteractions(mockCrypto)
        verifyNoMoreInteractions(mockFactory)

        XCTAssertEqual(encryptionHandshake.authMessagePacket, encryptedAuthMessage)
    }

    func testExtractSecretsFromResponse() {
        let noncesHash = Data(repeating: 7, count: 32)
        let sharedSecret = Data(repeating: 8, count: 32)
        let aes = Data(repeating: 9, count: 32)
        let mac = Data(repeating: 10, count: 32)
        let token = Data(repeating: 11, count: 32)
        let egressMac = KeccakDigest()
        let ingressMac = KeccakDigest()

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
            secrets = try encryptionHandshake.extractSecretsFromResponse(in: Data())
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        verify(mockCrypto).eciesDecrypt(privateKey: equal(to: myKey.privateKey), message: equal(to: Data()))
        verify(mockCrypto).ecdhAgree(myKey: equal(to: ephemeralKey), remotePublicKeyPoint: equal(to: remoteEphemeralKeyPoint))
        verify(mockCrypto).sha3(_: equal(to: remoteNonce + nonce))
        verify(mockCrypto).sha3(_: equal(to: ephemeralSharedSecret + noncesHash))
        verify(mockCrypto).sha3(_: equal(to: ephemeralSharedSecret + sharedSecret))
        verify(mockCrypto).sha3(_: equal(to: ephemeralSharedSecret + aes))
        verify(mockCrypto).sha3(_: equal(to: sharedSecret))
        verify(mockFactory).authAckMessage(data: equal(to: decryptedAuthAckMessage))
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

    func testExtractSecretsFromResponse_NonDecodableMessage() {
        stub(mockFactory) { mock in
            when(mock.authAckMessage(data: any())).thenReturn(nil)
        }

        do {
            _ = try encryptionHandshake.extractSecretsFromResponse(in: Data())
            XCTFail("Expecting error")
        } catch let error as EncryptionHandshake.HandshakeError {
            XCTAssertEqual(error, EncryptionHandshake.HandshakeError.invalidAuthAckPayload)
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

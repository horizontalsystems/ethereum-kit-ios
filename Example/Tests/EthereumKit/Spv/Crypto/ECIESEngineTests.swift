import XCTest
import Cuckoo
@testable import EthereumKit

class ECIESEngineTests: XCTestCase {
    private var mockCrypto: MockIECIESCryptoUtils!
    private var mockRandom: MockIRandomHelper!
    private var eciesEngine: ECIESEngine!

    private var myKey = RandomHelper.shared.randomKey()
    private var remotePublicKey = RandomHelper.shared.randomKey().publicKeyPoint
    private var message = Data(repeating: 10, count: 40)
    private var ephemeralKey = RandomHelper.shared.randomKey()
    private var initialVector = Data(repeating: 0, count: 16)
    private var sharedSecret = Data(repeating: 1, count: 32)
    private var derivedKey = Data(repeating: 2, count: 32)
    private var macKey = Data(repeating: 3, count: 16)
    private var cipher = Data(repeating: 4, count: 40)
    private var checksum = Data(repeating: 5, count: 32)
    private var prefixBytes: Data!

    override func setUp() {
        super.setUp()

        let prefix = UInt16(ECIESEngine.prefix + message.count)
        prefixBytes = Data(prefix.data.reversed())

        mockCrypto = MockIECIESCryptoUtils()
        mockRandom = MockIRandomHelper()

        stub(mockRandom) { mock in
            when(mock.randomBytes(length: equal(to: 16))).thenReturn(initialVector)
            when(mock.randomKey()).thenReturn(ephemeralKey)
        }

        stub(mockCrypto) { mock in
            when(mock.ecdhAgree(myKey: equal(to: ephemeralKey), remotePublicKeyPoint: equal(to: remotePublicKey))).thenReturn(sharedSecret)
            when(mock.ecdhAgree(myPrivateKey: equal(to: myKey.privateKey), remotePublicKeyPoint: equal(to: ephemeralKey.publicKeyPoint.uncompressed()))).thenReturn(sharedSecret)

            when(mock.concatKDF(_: equal(to: sharedSecret))).thenReturn(derivedKey)
            when(mock.sha256(_: equal(to: Data(derivedKey.subdata(in: 16..<32))))).thenReturn(macKey)
            when(mock.hmacSha256(_: equal(to: cipher), key: equal(to: macKey), iv: equal(to: initialVector), macData: equal(to: prefixBytes))).thenReturn(checksum)

            when(mock.aesEncrypt(_: equal(to: cipher), withKey: equal(to: Data(derivedKey.subdata(in: 0..<16))), keySize: equal(to: 128), iv: equal(to: initialVector))).thenReturn(message)
            when(mock.aesEncrypt(_: equal(to: message), withKey: equal(to: Data(derivedKey.subdata(in: 0..<16))), keySize: equal(to: 128), iv: equal(to: initialVector))).thenReturn(cipher)
        }

        eciesEngine = ECIESEngine()
    }

    override func tearDown() {
        mockCrypto = nil
        eciesEngine = nil
        prefixBytes = nil

        super.tearDown()
    }

    func testEncrypt() {
        let encrypted = eciesEngine.encrypt(crypto: mockCrypto, randomHelper: mockRandom, remotePublicKey: remotePublicKey, message: message)

        verify(mockRandom).randomBytes(length: equal(to: 16))
        verify(mockRandom).randomKey()
        verify(mockCrypto).ecdhAgree(myKey: equal(to: ephemeralKey), remotePublicKeyPoint: equal(to: remotePublicKey))
        verify(mockCrypto).concatKDF(_: equal(to: sharedSecret))
        verify(mockCrypto).sha256(_: equal(to: Data(derivedKey.subdata(in: 16..<32))))
        verify(mockCrypto).aesEncrypt(_: equal(to: message), withKey: equal(to: Data(derivedKey.subdata(in: 0..<16))), keySize: equal(to: 128), iv: equal(to: initialVector))
        verify(mockCrypto).hmacSha256(_: equal(to: cipher), key: equal(to: macKey), iv: equal(to: initialVector), macData: equal(to: prefixBytes))
        verifyNoMoreInteractions(mockCrypto)

        XCTAssertEqual(encrypted.prefixBytes, prefixBytes)
        XCTAssertEqual(encrypted.initialVector, initialVector)
        XCTAssertEqual(encrypted.ephemeralPublicKey, ephemeralKey.publicKeyPoint.uncompressed())
        XCTAssertEqual(encrypted.cipher, cipher)
        XCTAssertEqual(encrypted.checksum, checksum)
    }

    func testDecrypt() {
        let encrypted = ECIESEncryptedMessage(prefixBytes: prefixBytes, ephemeralPublicKey: ephemeralKey.publicKeyPoint.uncompressed(), initialVector: initialVector, cipher: cipher, checksum: checksum)

        let decrypted = try! eciesEngine.decrypt(crypto: mockCrypto, privateKey: myKey.privateKey, message: encrypted)

        verify(mockCrypto).ecdhAgree(myPrivateKey: equal(to: myKey.privateKey), remotePublicKeyPoint: equal(to: ephemeralKey.publicKeyPoint.uncompressed()))
        verify(mockCrypto).concatKDF(_: equal(to: sharedSecret))
        verify(mockCrypto).sha256(_: equal(to: Data(derivedKey.subdata(in: 16..<32))))
        verify(mockCrypto).hmacSha256(_: equal(to: cipher), key: equal(to: macKey), iv: equal(to: initialVector), macData: equal(to: prefixBytes))
        verify(mockCrypto).aesEncrypt(_: equal(to: cipher), withKey: equal(to: Data(derivedKey.subdata(in: 0..<16))), keySize: equal(to: 128), iv: equal(to: initialVector))
        verifyNoMoreInteractions(mockCrypto)

        XCTAssertEqual(decrypted, message)
    }

    func testDecrypt_ChecksumMismatch() {
        let encrypted = ECIESEncryptedMessage(prefixBytes: prefixBytes, ephemeralPublicKey: ephemeralKey.publicKeyPoint.uncompressed(), initialVector: initialVector, cipher: cipher, checksum: checksum)

        stub(mockCrypto) { mock in
            when(mock.hmacSha256(_: equal(to: cipher), key: equal(to: macKey), iv: equal(to: initialVector), macData: equal(to: prefixBytes))).thenReturn(Data())
        }

        do {
            let _ = try eciesEngine.decrypt(crypto: mockCrypto, privateKey: myKey.privateKey, message: encrypted)
            XCTFail("Error expected!")
        } catch let error as ECIESEngine.ECIESError {
            XCTAssertEqual(error, ECIESEngine.ECIESError.macMismatch)
        } catch {
            XCTFail("Unexpected error thrown!")
        }
    }

}

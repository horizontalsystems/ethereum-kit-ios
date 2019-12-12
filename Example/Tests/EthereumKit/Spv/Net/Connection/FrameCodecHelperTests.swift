import XCTest
import Cuckoo
import OpenSslKit
@testable import EthereumKit

class FrameCodecHelperTests: XCTestCase {
    private var mockCrypto: MockICryptoUtils!
    private var helper: FrameCodecHelper!

    private let keccak = KeccakDigest()
    private let keccak2 = KeccakDigest()
    private let encryptedMacDigest = Data(repeating: 0, count: 32)
    private let key = Data(repeating: 1, count: 16)
    private let data = Data(repeating: 2, count: 100)

    override func setUp() {
        super.setUp()

        mockCrypto = MockICryptoUtils()
        stub(mockCrypto) { mock in
            when(mock.aesEncrypt(_: equal(to: keccak.digest()), withKey: equal(to: key), keySize: equal(to: 256))).thenReturn(encryptedMacDigest)
        }

        helper = FrameCodecHelper(crypto: mockCrypto)
    }

    override func tearDown() {
        mockCrypto = nil
        helper = nil

        super.tearDown()
    }

    func testUpdateMac() {
        let result = helper.updateMac(mac: keccak, macKey: key, data: data)

        verify(mockCrypto).aesEncrypt(_: equal(to: keccak2.digest()), withKey: equal(to: key), keySize: equal(to: 256))
        verifyNoMoreInteractions(mockCrypto)

        keccak2.update(with: encryptedMacDigest.subdata(in: 0..<16).xor(with: data))

        XCTAssertEqual(keccak.digest(), keccak2.digest())
        XCTAssertEqual(result, keccak.digest().subdata(in: 0..<16))
    }

    func testToThreeBytes() {
        XCTAssertEqual(helper.toThreeBytes(int: 10), Data(hex: "00000a"))
        XCTAssertEqual(helper.toThreeBytes(int: 9448946), Data(hex: "902df2"))
        XCTAssertEqual(helper.toThreeBytes(int: 16777200), Data(hex: "fffff0"))
    }

    func testFromThreeBytes() {
        XCTAssertEqual(helper.fromThreeBytes(data: Data(hex: "00000a")!), 10)
        XCTAssertEqual(helper.fromThreeBytes(data: Data(hex: "902df2")!), 9448946)
        XCTAssertEqual(helper.fromThreeBytes(data: Data(hex: "fffff0")!), 16777200)
    }

}

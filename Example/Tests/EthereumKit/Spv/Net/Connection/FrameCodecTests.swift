import XCTest
import Cuckoo
import OpenSslKit
@testable import EthereumKit

class FrameCodecTests: XCTestCase {
    private var secrets: Secrets!
    private var mockEncryptor: MockIAESCipher!
    private var mockDecryptor: MockIAESCipher!
    private var mockHelper: MockIFrameCodecHelper!

    private let encryptedHeader = Data(repeating: 3, count: 16)
    private let encryptedBody = Data(repeating: 4, count: 16)
    private let headerMac = Data(repeating: 5, count: 16)
    private let bodyMac = Data(repeating: 6, count: 16)
    private let updatedEgressDigest = KeccakDigest()

    private var frameCodec: FrameCodec!

    override func setUp() {
        super.setUp()

        secrets = Secrets(
                aes: Data(repeating: 0, count: 16),
                mac: Data(repeating: 1, count: 16),
                token: Data(repeating: 2, count: 32),
                egressMac: KeccakDigest(), ingressMac: KeccakDigest()
        )
        mockEncryptor = MockIAESCipher()
        mockDecryptor = MockIAESCipher()
        mockHelper = MockIFrameCodecHelper()

        updatedEgressDigest.update(with: encryptedBody)
        stub(mockHelper) { mock in
            when(mock.updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))).thenReturn(headerMac)
            when(mock.updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))).thenReturn(bodyMac)
            when(mock.updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))).thenReturn(headerMac)
            when(mock.updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))).thenReturn(bodyMac)
        }

        frameCodec = FrameCodec(secrets: secrets, helper: mockHelper, encryptor: mockEncryptor, decryptor: mockDecryptor)
    }

    override func tearDown() {
        secrets = nil
        mockEncryptor = nil
        mockDecryptor = nil
        mockHelper = nil
        frameCodec = nil

        super.tearDown()
    }

    func testEncodeFrame() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 15), size: 10, contextId: -1, allFramesTotalSize: -1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let header = frameSizeBytes + RLP.encode([0]) + Data(repeating: 0, count: 11)
        let body = RLP.encode(frame.type) + frame.payload

        stub(mockEncryptor) { mock in
            when(mock.process(_: equal(to: header))).thenReturn(encryptedHeader)
            when(mock.process(_: equal(to: body))).thenReturn(encryptedBody)
        }

        stub(mockHelper) { mock in
            when(mock.toThreeBytes(int: equal(to: frame.payloadSize + 1))).thenReturn(frameSizeBytes)
        }

        let result = frameCodec.encodeFrame(frame: frame)

        verify(mockEncryptor).process(_: equal(to: header))
        verify(mockEncryptor).process(_: equal(to: body))
        verify(mockHelper).toThreeBytes(int: equal(to: frame.payloadSize + 1))
        verify(mockHelper).updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))
        verify(mockHelper).updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))

        verifyNoMoreInteractions(mockEncryptor)
        verifyNoMoreInteractions(mockHelper)

        XCTAssertEqual(result, encryptedHeader + headerMac + encryptedBody + bodyMac)
    }

    func testEncodeFrame_contextId() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 15), size: 10, contextId: 1, allFramesTotalSize: 1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let headerPadding = Data(repeating: 0, count: 16 - frameSizeBytes.count - RLP.encode([0, 1, 1]).count)
        let header = frameSizeBytes + RLP.encode([0, 1, 1]) + headerPadding
        let body = RLP.encode(frame.type) + frame.payload

        stub(mockEncryptor) { mock in
            when(mock.process(_: equal(to: header))).thenReturn(encryptedHeader)
            when(mock.process(_: equal(to: body))).thenReturn(encryptedBody)
        }

        stub(mockHelper) { mock in
            when(mock.toThreeBytes(int: equal(to: frame.payloadSize + 1))).thenReturn(frameSizeBytes)
        }

        let result = frameCodec.encodeFrame(frame: frame)

        verify(mockEncryptor).process(_: equal(to: header))
        verify(mockEncryptor).process(_: equal(to: body))
        verify(mockHelper).toThreeBytes(int: equal(to: frame.payloadSize + 1))
        verify(mockHelper).updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))
        verify(mockHelper).updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))

        verifyNoMoreInteractions(mockEncryptor)
        verifyNoMoreInteractions(mockHelper)

        XCTAssertEqual(result, encryptedHeader + headerMac + encryptedBody + bodyMac)
    }

    func testEncodeFrame_framePadding() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 16), size: 10, contextId: -1, allFramesTotalSize: -1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let header = frameSizeBytes + RLP.encode([0]) + Data(repeating: 0, count: 11)
        let body = RLP.encode(frame.type) + frame.payload + Data(repeating: 0, count: 15)

        stub(mockEncryptor) { mock in
            when(mock.process(_: equal(to: header))).thenReturn(encryptedHeader)
            when(mock.process(_: equal(to: body))).thenReturn(encryptedBody)
        }

        stub(mockHelper) { mock in
            when(mock.toThreeBytes(int: equal(to: frame.payloadSize + 1))).thenReturn(frameSizeBytes)
        }

        let result = frameCodec.encodeFrame(frame: frame)

        verify(mockEncryptor).process(_: equal(to: header))
        verify(mockEncryptor).process(_: equal(to: body))
        verify(mockHelper).toThreeBytes(int: equal(to: frame.payloadSize + 1))
        verify(mockHelper).updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))
        verify(mockHelper).updateMac(mac: equal(to: secrets.egressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))

        verifyNoMoreInteractions(mockEncryptor)
        verifyNoMoreInteractions(mockHelper)

        XCTAssertEqual(result, encryptedHeader + headerMac + encryptedBody + bodyMac)
    }

    func testReadFrame() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 15), size: 64, contextId: -1, allFramesTotalSize: -1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let header = frameSizeBytes + RLP.encode([0]) + Data(repeating: 0, count: 11)
        let body = RLP.encode(frame.type) + frame.payload

        stub(mockDecryptor) { mock in
            when(mock.process(_: equal(to: encryptedHeader))).thenReturn(header)
            when(mock.process(_: equal(to: encryptedBody))).thenReturn(body)
        }

        stub(mockHelper) { mock in
            when(mock.fromThreeBytes(data: equal(to: frameSizeBytes))).thenReturn(frame.payloadSize + 1)
        }

        let result = try! frameCodec.readFrame(from: encryptedHeader + headerMac + encryptedBody + bodyMac)!

        verify(mockDecryptor).process(_: equal(to: encryptedHeader))
        verify(mockDecryptor).process(_: equal(to: encryptedBody))
        verify(mockHelper).fromThreeBytes(data: equal(to: frameSizeBytes))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))

        verifyNoMoreInteractions(mockDecryptor)
        verifyNoMoreInteractions(mockHelper)

        XCTAssertEqual(result.type, frame.type)
        XCTAssertEqual(result.payload, frame.payload)
        XCTAssertEqual(result.payloadSize, frame.payloadSize)
        XCTAssertEqual(result.size, frame.size)
        XCTAssertEqual(result.contextId, frame.contextId)
        XCTAssertEqual(result.allFramesTotalSize, frame.allFramesTotalSize)
    }

    func testReadFrame_ContextId() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 15), size: 64, contextId: 1, allFramesTotalSize: 1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let header = frameSizeBytes + RLP.encode([0, 1, 1]) + Data(repeating: 0, count: 9)
        let body = RLP.encode(frame.type) + frame.payload

        stub(mockDecryptor) { mock in
            when(mock.process(_: equal(to: encryptedHeader))).thenReturn(header)
            when(mock.process(_: equal(to: encryptedBody))).thenReturn(body)
        }

        stub(mockHelper) { mock in
            when(mock.fromThreeBytes(data: equal(to: frameSizeBytes))).thenReturn(frame.payloadSize + 1)
        }

        let result = try! frameCodec.readFrame(from: encryptedHeader + headerMac + encryptedBody + bodyMac)!

        verify(mockDecryptor).process(_: equal(to: encryptedHeader))
        verify(mockDecryptor).process(_: equal(to: encryptedBody))
        verify(mockHelper).fromThreeBytes(data: equal(to: frameSizeBytes))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))

        verifyNoMoreInteractions(mockDecryptor)
        verifyNoMoreInteractions(mockHelper)

        XCTAssertEqual(result.type, frame.type)
        XCTAssertEqual(result.payload, frame.payload)
        XCTAssertEqual(result.payloadSize, frame.payloadSize)
        XCTAssertEqual(result.size, frame.size)
        XCTAssertEqual(result.contextId, frame.contextId)
        XCTAssertEqual(result.allFramesTotalSize, frame.allFramesTotalSize)
    }

    func testReadFrame_bodyPadding() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 16), size: 80, contextId: -1, allFramesTotalSize: -1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let header = frameSizeBytes + RLP.encode([0]) + Data(repeating: 0, count: 11)
        let body = RLP.encode(frame.type) + frame.payload

        let encryptedBody = self.encryptedBody + Data(repeating: 0, count: 1) + Data(repeating: 0, count: 15)
        let updatedEgressDigest = KeccakDigest()
        updatedEgressDigest.update(with: encryptedBody)
        stub(mockHelper) { mock in
            when(mock.updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))).thenReturn(bodyMac)
        }

        stub(mockDecryptor) { mock in
            when(mock.process(_: equal(to: encryptedHeader))).thenReturn(header)
            when(mock.process(_: equal(to: encryptedBody))).thenReturn(body)
        }

        stub(mockHelper) { mock in
            when(mock.fromThreeBytes(data: equal(to: frameSizeBytes))).thenReturn(frame.payloadSize + 1)
        }

        let result = try! frameCodec.readFrame(from: encryptedHeader + headerMac + encryptedBody + bodyMac)!

        verify(mockDecryptor).process(_: equal(to: encryptedHeader))
        verify(mockDecryptor).process(_: equal(to: encryptedBody))
        verify(mockHelper).fromThreeBytes(data: equal(to: frameSizeBytes))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))

        verifyNoMoreInteractions(mockDecryptor)
        verifyNoMoreInteractions(mockHelper)

        XCTAssertEqual(result.type, frame.type)
        XCTAssertEqual(result.payload, frame.payload)
        XCTAssertEqual(result.payloadSize, frame.payloadSize)
        XCTAssertEqual(result.size, frame.size)
        XCTAssertEqual(result.contextId, frame.contextId)
        XCTAssertEqual(result.allFramesTotalSize, frame.allFramesTotalSize)
    }

    func testReadFrame_notEnoughBytes() {
        let result = try! frameCodec.readFrame(from: Data(repeating: 0, count: 63))
        XCTAssertNil(result)
    }

    func testReadFrame_notEnoughBytes2() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 15), size: 64, contextId: -1, allFramesTotalSize: -1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let header = frameSizeBytes + RLP.encode([0]) + Data(repeating: 0, count: 11)

        stub(mockDecryptor) { mock in
            when(mock.process(_: equal(to: encryptedHeader))).thenReturn(header)
        }

        stub(mockHelper) { mock in
            when(mock.fromThreeBytes(data: equal(to: frameSizeBytes))).thenReturn(frame.payloadSize + 1 + 10)
        }

        let result = try! frameCodec.readFrame(from: encryptedHeader + headerMac + encryptedBody + bodyMac)

        verify(mockHelper).fromThreeBytes(data: equal(to: frameSizeBytes))
        verify(mockDecryptor).process(_: equal(to: encryptedHeader))

        XCTAssertNil(result)
    }

    func testReadFrame_HeaderMacMismatch() {
        do {
            let _ = try frameCodec.readFrame(from: encryptedHeader + Data(repeating: 11, count: 16) + encryptedBody + bodyMac)
            XCTFail("Error expected")
        } catch let error as FrameCodec.FrameCodecError {
            XCTAssertEqual(error, FrameCodec.FrameCodecError.macMismatch)
        } catch {
            XCTFail("Unexpected Error")
        }

        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))

        verifyNoMoreInteractions(mockDecryptor)
        verifyNoMoreInteractions(mockHelper)
    }

    func testReadFrame_BodyMacMismatch() {
        let frame = Frame(type: 0, payload: Data(repeating: 10, count: 15), size: 64, contextId: -1, allFramesTotalSize: -1)
        let frameSizeBytes = Data(repeating: 0, count: 3)
        let header = frameSizeBytes + RLP.encode([0]) + Data(repeating: 0, count: 11)
        let body = RLP.encode(frame.type) + frame.payload

        stub(mockDecryptor) { mock in
            when(mock.process(_: equal(to: encryptedHeader))).thenReturn(header)
            when(mock.process(_: equal(to: encryptedBody))).thenReturn(body)
        }

        stub(mockHelper) { mock in
            when(mock.fromThreeBytes(data: equal(to: frameSizeBytes))).thenReturn(frame.payloadSize + 1)
        }

        do {
            let _ = try frameCodec.readFrame(from: encryptedHeader + headerMac + encryptedBody + Data(repeating: 11, count: 16))
            XCTFail("Error expected")
        } catch let error as FrameCodec.FrameCodecError {
            XCTAssertEqual(error, FrameCodec.FrameCodecError.macMismatch)
        } catch {
            XCTFail("Unexpected Error")
        }

        verify(mockDecryptor).process(_: equal(to: encryptedHeader))
        verify(mockDecryptor).process(_: equal(to: encryptedBody))
        verify(mockHelper).fromThreeBytes(data: equal(to: frameSizeBytes))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: encryptedHeader))
        verify(mockHelper).updateMac(mac: equal(to: secrets.ingressMac), macKey: equal(to: secrets.mac), data: equal(to: updatedEgressDigest.digest()))

        verifyNoMoreInteractions(mockDecryptor)
        verifyNoMoreInteractions(mockHelper)
    }

}

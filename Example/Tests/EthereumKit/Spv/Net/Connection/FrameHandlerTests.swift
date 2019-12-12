//import XCTest
//import Cuckoo
//@testable import EthereumKit
//
//class FrameHandlerTests: XCTestCase {
//    private var frameHandler: MessageHandler!
//
//    override func setUp() {
//        super.setUp()
//
//        frameHandler = MessageHandler()
//    }
//
//    override func tearDown() {
//        frameHandler = nil
//
//        super.tearDown()
//    }
//
//    func testGetMessage() {
//        let message = HelloMessage(peerId: Data(repeating: 0, count: 64), port: 0, capabilities: [])
//        frameHandler.add(frame: Frame(type: 0, payload: message.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//
//        guard let resolvedMessage = try! frameHandler.getMessage() as? HelloMessage else {
//            XCTFail("Expected to resolve HelloMessage")
//            return
//        }
//
//        XCTAssertEqual(resolvedMessage.encoded(), message.encoded())
//    }
//
//    func testGetMessage_EmptyFrames() {
//        let resolvedMessage = try! frameHandler.getMessage()
//
//        XCTAssertNil(resolvedMessage)
//    }
//
//    func testGetMessage_UnknownMessageType() {
//        let helloMessage = HelloMessage(peerId: Data(repeating: 0, count: 64), port: 0, capabilities: [])
//        frameHandler.add(frame: Frame(type: 5, payload: helloMessage.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//
//        do {
//            let _ = try frameHandler.getMessage()
//            XCTFail("Expected to throw error")
//        } catch let error as MessageHandler.FrameHandlerError {
//            XCTAssertEqual(error, MessageHandler.FrameHandlerError.unknownMessageType)
//        } catch {
//            XCTFail("Unexpected error thrown")
//        }
//    }
//
//    func testGetMessage_InvalidPayload() {
//        frameHandler.add(frame: Frame(type: 0, payload: PingMessage().encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//
//        do {
//            let _ = try frameHandler.getMessage()
//            XCTFail("Expected to throw error")
//        } catch let error as MessageHandler.FrameHandlerError {
//            XCTAssertEqual(error, MessageHandler.FrameHandlerError.invalidPayload)
//        } catch {
//            XCTFail("Unexpected error thrown")
//        }
//    }
//
//    func testGetMessage_TwoMessagesInFrames() {
//        let helloMessage = HelloMessage(peerId: Data(repeating: 0, count: 64), port: 0, capabilities: [])
//        let pingMessage = PingMessage()
//
//        frameHandler.add(frame: Frame(type: 0, payload: helloMessage.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//        frameHandler.add(frame: Frame(type: 2, payload: pingMessage.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//
//        guard let resolvedHelloMessage = try! frameHandler.getMessage() as? HelloMessage else {
//            XCTFail("Expected to resolve HelloMessage")
//            return
//        }
//        XCTAssertEqual(resolvedHelloMessage.encoded(), helloMessage.encoded())
//
//        guard let resolvedPingMessage = try! frameHandler.getMessage() as? PingMessage else {
//            XCTFail("Expected to resolve PingMessage")
//            return
//        }
//        XCTAssertEqual(resolvedPingMessage.encoded(), pingMessage.encoded())
//    }
//
//    func testRegister() {
//        let capability = Capability(name: "tst", version: 1, packetTypesMap: [
//            0x00: TestMessage1.self,
//            0x01: TestMessage2.self
//        ])
//        frameHandler.register(capabilities: [capability])
//
//        let helloMessage = HelloMessage(peerId: Data(repeating: 0, count: 64), port: 0, capabilities: [])
//        let testMessage = TestMessage1()
//
//        frameHandler.add(frame: Frame(type: 0, payload: helloMessage.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//        frameHandler.add(frame: Frame(type: 0x10, payload: testMessage.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//
//        guard let resolvedHelloMessage = try! frameHandler.getMessage() as? HelloMessage else {
//            XCTFail("Expected to resolve HelloMessage")
//            return
//        }
//        XCTAssertEqual(resolvedHelloMessage.encoded(), helloMessage.encoded())
//
//        guard let resolvedTestMessage = try! frameHandler.getMessage() as? TestMessage1 else {
//            XCTFail("Expected to resolve TestMessage1")
//            return
//        }
//        XCTAssertEqual(resolvedTestMessage.encoded(), testMessage.encoded())
//    }
//
//    func testRegister_TwoCapabilities() {
//        let capability = Capability(name: "ast", version: 1, packetTypesMap: [
//            0x05: TestMessage1.self
//        ])
//        let capability2 = Capability(name: "bst", version: 1, packetTypesMap: [
//            0x05: TestMessage2.self
//        ])
//        let capability3 = Capability(name: "bst", version: 2, packetTypesMap: [
//            0x05: TestMessage3.self
//        ])
//        frameHandler.register(capabilities: [capability3, capability2, capability])
//
//        let testMessage = TestMessage1()
//        let testMessage2 = TestMessage2()
//        let testMessage3 = TestMessage3()
//        frameHandler.add(frame: Frame(type: 0x15, payload: testMessage.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//        frameHandler.add(frame: Frame(type: 0x1a, payload: testMessage2.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//        frameHandler.add(frame: Frame(type: 0x1f, payload: testMessage3.encoded(), size: 0, contextId: 0, allFramesTotalSize: 0))
//
//        guard let resolvedTestMessage = try! frameHandler.getMessage() as? TestMessage1 else {
//            XCTFail("Expected to resolve TestMessage1")
//            return
//        }
//        XCTAssertEqual(resolvedTestMessage.encoded(), testMessage.encoded())
//
//        guard let resolvedTest2Message = try! frameHandler.getMessage() as? TestMessage2 else {
//            XCTFail("Expected to resolve HelloMessage2")
//            return
//        }
//        XCTAssertEqual(resolvedTest2Message.encoded(), testMessage2.encoded())
//
//        guard let resolvedTest3Message = try! frameHandler.getMessage() as? TestMessage3 else {
//            XCTFail("Expected to resolve HelloMessage2")
//            return
//        }
//        XCTAssertEqual(resolvedTest3Message.encoded(), testMessage2.encoded())
//    }
//
//    func testGetFrames() {
//        let helloMessage = HelloMessage(peerId: Data(repeating: 0, count: 64), port: 0, capabilities: [])
//        let frames = frameHandler.getFrames(from: helloMessage)
//
//        XCTAssertEqual(frames.count, 1)
//        XCTAssertEqual(frames[0].type, 0)
//        XCTAssertEqual(frames[0].payload, helloMessage.encoded())
//        XCTAssertEqual(frames[0].payloadSize, helloMessage.encoded().count)
//        XCTAssertEqual(frames[0].contextId, -1)
//        XCTAssertEqual(frames[0].allFramesTotalSize, -1)
//    }
//
//
//    class TestMessage1: IMessage {
//        init() {
//        }
//
//        required init(data: Data) throws {
//        }
//
//        func encoded() -> Data {
//            return Data()
//        }
//
//        func toString() -> String {
//            return ""
//        }
//    }
//
//    class TestMessage2: IMessage {
//        init() {
//        }
//
//        required init(data: Data) throws {
//        }
//
//        func encoded() -> Data {
//            return Data()
//        }
//
//        func toString() -> String {
//            return ""
//        }
//    }
//
//    class TestMessage3: IMessage {
//        init() {
//        }
//
//        required init(data: Data) throws {
//        }
//
//        func encoded() -> Data {
//            return Data()
//        }
//
//        func toString() -> String {
//            return ""
//        }
//    }
//
//}

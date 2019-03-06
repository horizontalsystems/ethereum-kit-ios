import XCTest
import Cuckoo
@testable import HSEthereumKit

class DevP2PPeerTests: XCTestCase {
    private var mockConnection: MockIConnection!
    private var mockFactory: MockIMessageFactory!
    private var mockDelegate: MockIDevP2PPeerDelegate!
    private var peer: DevP2PPeer!

    private let key = ECKey(privateKey: Data(), publicKeyPoint: ECPoint(nodeId: Data(repeating: 0, count: 64)))
    private let capability = Capability(name: "capability", version: 1)

    override func setUp() {
        super.setUp()

        mockConnection = MockIConnection()
        mockFactory = MockIMessageFactory()
        mockDelegate = MockIDevP2PPeerDelegate()

        peer = DevP2PPeer(connection: mockConnection, key: key, capability: capability, messageFactory: mockFactory)
        peer.delegate = mockDelegate
    }

    override func tearDown() {
        mockConnection = nil
        mockFactory = nil
        mockDelegate = nil

        peer = nil

        super.tearDown()
    }

    func testConnect() {
        stub(mockConnection) { mock in
            when(mock.connect()).thenDoNothing()
        }

        peer.connect()

        verify(mockConnection).connect()
    }

    func testDisconnect() {
        class TestError: Error {}

        let error = TestError()

        stub(mockConnection) { mock in
            when(mock.disconnect(error: any())).thenDoNothing()
        }

        peer.disconnect(error: error)

        verify(mockConnection).disconnect(error: equal(to: error, type: TestError.self))
    }

    func testSendMessage() {
        let message = MockIMessage(data: Data())

        stub(mockConnection) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.send(message: message)

        verify(mockConnection).send(message: equal(to: message, type: MockIMessage.self))
    }

    func testDidEstablishConnection() {
        let mockHelloMessage = MockIHelloMessage(data: Data())

        stub(mockFactory) { mock in
            when(mock.helloMessage(key: equal(to: key), capabilities: equal(to: [capability]))).thenReturn(mockHelloMessage)
        }
        stub(mockConnection) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.didEstablishConnection()

        verify(mockConnection).send(message: equal(to: mockHelloMessage, type: MockIHelloMessage.self))
    }

    func testDidDisconnect() {
        class TestError: Error {}
        let error = TestError()

        stub(mockDelegate) { mock in
            when(mock.didDisconnect(error: any())).thenDoNothing()
        }

        peer.didDisconnect(error: error)

        verify(mockDelegate).didDisconnect(error: equal(to: error, type: TestError.self))
    }

    func testDidReceive_helloMessage() {
        let mockHelloMessage = MockIHelloMessage(data: Data())
        let anotherCapability = Capability(name: "anotherCapability", version: 2)

        stub(mockHelloMessage) { mock in
            when(mock.capabilities.get).thenReturn([anotherCapability, capability])
        }
        stub(mockConnection) { mock in
            when(mock.register(capabilities: any())).thenDoNothing()
        }
        stub(mockDelegate) { mock in
            when(mock.didEstablishConnection()).thenDoNothing()
        }

        peer.didReceive(message: mockHelloMessage)

        verify(mockConnection).register(capabilities: equal(to: [capability]))
        verify(mockDelegate).didEstablishConnection()
    }

    func testDidReceive_helloMessage_noCapability() {
        let mockHelloMessage = MockIHelloMessage(data: Data())
        let anotherCapability = Capability(name: "anotherCapability", version: 2)

        stub(mockHelloMessage) { mock in
            when(mock.capabilities.get).thenReturn([anotherCapability])
        }
        stub(mockConnection) { mock in
            when(mock.disconnect(error: any())).thenDoNothing()
        }

        peer.didReceive(message: mockHelloMessage)

        let expectedError: Error = DevP2PPeer.DevP2PPeerError.peerDoesNotSupportCapability
        verify(mockConnection).disconnect(error: equal(to: expectedError, equalWhen: { $0 as! DevP2PPeer.DevP2PPeerError == $1 as! DevP2PPeer.DevP2PPeerError }))
    }

    func testDidReceive_pingMessage() {
        let mockPingMessage = MockIPingMessage(data: Data())
        let mockPongMessage = MockIPongMessage(data: Data())

        stub(mockFactory) { mock in
            when(mock.pongMessage()).thenReturn(mockPongMessage)
        }
        stub(mockConnection) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.didReceive(message: mockPingMessage)

        verify(mockConnection).send(message: equal(to: mockPongMessage, type: MockIPongMessage.self))
    }

    func testDidReceive_pongMessage() {
        let mockPongMessage = MockIPongMessage(data: Data())

        peer.didReceive(message: mockPongMessage)

        verifyNoMoreInteractions(mockConnection)
        verifyNoMoreInteractions(mockDelegate)
    }

    func testDidReceive_disconnectMessage() {
        let mockDisconnectMessage = MockIDisconnectMessage(data: Data())

        stub(mockConnection) { mock in
            when(mock.disconnect(error: any())).thenDoNothing()
        }

        peer.didReceive(message: mockDisconnectMessage)

        let expectedError: Error = DevP2PPeer.DevP2PPeerError.disconnectMessageReceived
        verify(mockConnection).disconnect(error: equal(to: expectedError, equalWhen: { $0 as! DevP2PPeer.DevP2PPeerError == $1 as! DevP2PPeer.DevP2PPeerError }))
    }

}

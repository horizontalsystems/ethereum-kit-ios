import XCTest
import Cuckoo
@testable import HSEthereumKit

class DevP2PPeerTests: XCTestCase {
    private var mockConnection: MockIDevP2PConnection!
    private var mockFactory: MockIMessageFactory!
    private var mockDelegate: MockIDevP2PPeerDelegate!
    private var peer: DevP2PPeer!

    private let key = ECKey(privateKey: Data(), publicKeyPoint: ECPoint(nodeId: Data(repeating: 0, count: 64)))
    private let capability = Capability(name: "capability", version: 1)

    override func setUp() {
        super.setUp()

        mockConnection = MockIDevP2PConnection()
        mockFactory = MockIMessageFactory()
        mockDelegate = MockIDevP2PPeerDelegate()

        peer = DevP2PPeer(devP2PConnection: mockConnection, messageFactory: mockFactory, key: key)
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
        let error = TestError()

        stub(mockConnection) { mock in
            when(mock.disconnect(error: any())).thenDoNothing()
        }

        peer.disconnect(error: error)

        verify(mockConnection).disconnect(error: equal(to: error, type: TestError.self))
    }

    func testSendMessage() {
        let message = MockIOutMessage()

        stub(mockConnection) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.send(message: message)

        verify(mockConnection).send(message: equal(to: message, type: MockIOutMessage.self))
    }

    func testDidConnect() {
        let helloMessage = HelloMessage()

        stub(mockFactory) { mock in
            when(mock.helloMessage(key: equal(to: key), capabilities: equal(to: [capability]))).thenReturn(helloMessage)
        }
        stub(mockConnection) { mock in
            when(mock.myCapabilities.get).thenReturn([capability])
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.didConnect()

        verify(mockConnection).send(message: equal(to: helloMessage, type: HelloMessage.self))
    }

    func testDidDisconnect() {
        let error = TestError()

        stub(mockDelegate) { mock in
            when(mock.didDisconnect(error: any())).thenDoNothing()
        }

        peer.didDisconnect(error: error)

        verify(mockDelegate).didDisconnect(error: equal(to: error, type: TestError.self))
    }

    func testDidReceive_helloMessage() {
        let helloMessage = HelloMessage(capabilities: [capability])

        stub(mockConnection) { mock in
            when(mock.register(nodeCapabilities: any())).thenDoNothing()
        }
        stub(mockDelegate) { mock in
            when(mock.didConnect()).thenDoNothing()
        }

        peer.didReceive(message: helloMessage)

        verify(mockConnection).register(nodeCapabilities: equal(to: [capability]))
        verify(mockDelegate).didConnect()
    }

    func testDidReceive_disconnectMessage() {
        let disconnectMessage = DisconnectMessage()

        stub(mockConnection) { mock in
            when(mock.disconnect(error: any())).thenDoNothing()
        }

        peer.didReceive(message: disconnectMessage)

        let expectedError: Error = DevP2PPeer.DisconnectError.disconnectMessageReceived
        verify(mockConnection).disconnect(error: equal(to: expectedError, equalWhen: { $0 as! DevP2PPeer.DisconnectError == $1 as! DevP2PPeer.DisconnectError }))
    }

    func testDidReceive_pingMessage() {
        let pingMessage = PingMessage()
        let pongMessage = PongMessage()

        stub(mockFactory) { mock in
            when(mock.pongMessage()).thenReturn(pongMessage)
        }
        stub(mockConnection) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.didReceive(message: pingMessage)

        verify(mockConnection).send(message: equal(to: pongMessage, type: PongMessage.self))
    }

    func testDidReceive_pongMessage() {
        let pongMessage = PongMessage()

        peer.didReceive(message: pongMessage)

        verifyNoMoreInteractions(mockConnection)
        verifyNoMoreInteractions(mockDelegate)
    }

}

import XCTest
import Cuckoo
@testable import HSEthereumKit

class LESPeerTests: XCTestCase {
    private var mockDevP2PPeer: MockIDevP2PPeer!
    private var mockFactory: MockIMessageFactory!
    private var mockValidator: MockILESPeerValidator!
    private var mockNetwork: MockINetwork!
    private var mockDelegate: MockILESPeerDelegate!
    private var peer: LESPeer!

    private let blockHeader = BlockHeader()

    override func setUp() {
        super.setUp()

        mockDevP2PPeer = MockIDevP2PPeer()
        mockFactory = MockIMessageFactory()
        mockValidator = MockILESPeerValidator()
        mockNetwork = MockINetwork()
        mockDelegate = MockILESPeerDelegate()

        peer = LESPeer(devP2PPeer: mockDevP2PPeer, messageFactory: mockFactory, validator: mockValidator, network: mockNetwork, lastBlockHeader: blockHeader)
        peer.delegate = mockDelegate
    }

    override func tearDown() {
        mockDevP2PPeer = nil
        mockFactory = nil
        mockValidator = nil
        mockNetwork = nil
        mockDelegate = nil

        peer = nil

        super.tearDown()
    }

    func testConnect() {
        stub(mockDevP2PPeer) { mock in
            when(mock.connect()).thenDoNothing()
        }

        peer.connect()

        verify(mockDevP2PPeer).connect()
    }

    func testDisconnect() {
        let error = TestError()

        stub(mockDevP2PPeer) { mock in
            when(mock.disconnect(error: any())).thenDoNothing()
        }

        peer.disconnect(error: error)

        verify(mockDevP2PPeer).disconnect(error: equal(to: error, type: TestError.self))
    }

    func testRequestBlockHeaders() {
        let blockHash = Data(repeating: 1, count: 10)
        let getBlockHeadersMessage = GetBlockHeadersMessage()

        stub(mockFactory) { mock in
            when(mock.getBlockHeadersMessage(blockHash: equal(to: blockHash))).thenReturn(getBlockHeadersMessage)
        }
        stub(mockDevP2PPeer) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.requestBlockHeaders(fromBlockHash: blockHash)

        verify(mockDevP2PPeer).send(message: equal(to: getBlockHeadersMessage, type: GetBlockHeadersMessage.self))
    }

    func testRequestProofs() {
        let address = Data(repeating: 1, count: 10)
        let blockHash = Data(repeating: 2, count: 10)
        let getProofsMessage = GetProofsMessage()

        stub(mockFactory) { mock in
            when(mock.getProofsMessage(address: equal(to: address), blockHash: equal(to: blockHash))).thenReturn(getProofsMessage)
        }
        stub(mockDevP2PPeer) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.requestProofs(forAddress: address, inBlockWithHash: blockHash)

        verify(mockDevP2PPeer).send(message: equal(to: getProofsMessage, type: GetProofsMessage.self))
    }

    func testDidConnect() {
        let statusMessage = StatusMessage()

        stub(mockFactory) { mock in
            when(mock.statusMessage(network: equal(to: mockNetwork, type: MockINetwork.self), blockHeader: equal(to: blockHeader))).thenReturn(statusMessage)
        }
        stub(mockDevP2PPeer) { mock in
            when(mock.send(message: any())).thenDoNothing()
        }

        peer.didConnect()

        verify(mockDevP2PPeer).send(message: equal(to: statusMessage, type: StatusMessage.self))
    }

    func testDidReceive_statusMessage() {
        let statusMessage = StatusMessage()

        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: statusMessage), network: equal(to: mockNetwork, type: MockINetwork.self), blockHeader: equal(to: blockHeader))).thenDoNothing()
        }
        stub(mockDelegate) { mock in
            when(mock.didConnect()).thenDoNothing()
        }

        peer.didReceive(message: statusMessage)

        verify(mockDelegate).didConnect()
    }

    func testDidReceive_statusMessage_invalid() {
        let error = TestError()
        let statusMessage = StatusMessage()

        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: statusMessage), network: equal(to: mockNetwork, type: MockINetwork.self), blockHeader: equal(to: blockHeader))).thenThrow(error)
        }
        stub(mockDevP2PPeer) { mock in
            when(mock.disconnect(error: any())).thenDoNothing()
        }

        peer.didReceive(message: statusMessage)

        verify(mockDelegate, never()).didConnect()
        verify(mockDevP2PPeer).disconnect(error: equal(to: error, type: TestError.self))
    }

    func testDidReceive_blockHeadersMessage() {
        let blockHeaders = [
            BlockHeader(hashHex: Data(repeating: 1, count: 5)),
            BlockHeader(hashHex: Data(repeating: 2, count: 5))
        ]
        let blockHeadersMessage = BlockHeadersMessage(headers: blockHeaders)

        stub(mockDelegate) { mock in
            when(mock.didReceive(blockHeaders: any())).thenDoNothing()
        }

        peer.didReceive(message: blockHeadersMessage)

        verify(mockDelegate).didReceive(blockHeaders: equal(to: blockHeaders))
    }

}

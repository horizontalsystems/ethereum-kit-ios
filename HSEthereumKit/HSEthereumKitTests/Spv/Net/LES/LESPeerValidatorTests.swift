import XCTest
import Cuckoo
@testable import HSEthereumKit

class LESPeerValidatorTests: XCTestCase {
    private var mockNetwork: MockINetwork!
    private var validator: LESPeerValidator!

    override func setUp() {
        super.setUp()

        mockNetwork = MockINetwork()
        validator = LESPeerValidator()
    }

    override func tearDown() {
        mockNetwork = nil
        validator = nil

        super.tearDown()
    }

    func testInvalidNetworkId() {
        let messageNetworkId = 1
        let networkId = 2

        let message = StatusMessage(networkId: messageNetworkId)

        stub(mockNetwork) { mock in
            when(mock.id.get).thenReturn(networkId)
        }

        XCTAssertThrowsError(
            try validator.validate(message: message, network: mockNetwork, blockHeader: BlockHeader())
        ) { error in
            XCTAssertEqual(error as! LESPeer.ValidationError, LESPeer.ValidationError.wrongNetwork)
        }
    }

    func testInvalidGenesisHash() {
        let messageNetworkId = 1
        let networkId = 1

        let messageHash = Data(repeating: 1, count: 10)
        let networkHash = Data(repeating: 2, count: 10)

        let message = StatusMessage(networkId: messageNetworkId, genesisHash: messageHash)

        stub(mockNetwork) { mock in
            when(mock.id.get).thenReturn(networkId)
            when(mock.genesisBlockHash.get).thenReturn(networkHash)
        }

        XCTAssertThrowsError(
            try validator.validate(message: message, network: mockNetwork, blockHeader: BlockHeader())
        ) { error in
            XCTAssertEqual(error as! LESPeer.ValidationError, LESPeer.ValidationError.wrongNetwork)
        }
    }

    func testInvalidHeadHeight_Equal() {
        let messageNetworkId = 1
        let networkId = 1

        let messageHash = Data(repeating: 1, count: 10)
        let networkHash = Data(repeating: 1, count: 10)

        let messageHeight: BInt = 99
        let blockHeight: BInt = 100

        let message = StatusMessage(networkId: messageNetworkId, genesisHash: messageHash, headHeight: messageHeight)
        let blockHeader = BlockHeader(height: blockHeight)

        stub(mockNetwork) { mock in
            when(mock.id.get).thenReturn(networkId)
            when(mock.genesisBlockHash.get).thenReturn(networkHash)
        }

        XCTAssertThrowsError(
            try validator.validate(message: message, network: mockNetwork, blockHeader: blockHeader)
        ) { error in
            XCTAssertEqual(error as! LESPeer.ValidationError, LESPeer.ValidationError.peerHasExpiredBlockChain(localHeight: blockHeight, peerHeight: messageHeight))
        }
    }

    func testValid() {
        let messageNetworkId = 1
        let networkId = 1

        let messageHash = Data(repeating: 1, count: 10)
        let networkHash = Data(repeating: 1, count: 10)

        let messageHeight: BInt = 100
        let blockHeight: BInt = 100

        let message = StatusMessage(networkId: messageNetworkId, genesisHash: messageHash, headHeight: messageHeight)
        let blockHeader = BlockHeader(height: blockHeight)

        stub(mockNetwork) { mock in
            when(mock.id.get).thenReturn(networkId)
            when(mock.genesisBlockHash.get).thenReturn(networkHash)
        }

        XCTAssertNoThrow(try validator.validate(message: message, network: mockNetwork, blockHeader: blockHeader))
    }

}

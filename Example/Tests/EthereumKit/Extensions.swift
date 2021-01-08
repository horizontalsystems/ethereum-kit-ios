import XCTest
import Cuckoo
import BigInt
import Socket
import OpenSslKit
@testable import EthereumKit

class TestError: Error {}

func equal<T, T2: AnyObject>(to value: T, type: T2.Type) -> ParameterMatcher<T> {
    return equal(to: value) { $0 as! T2 === $1 as! T2 }
}

func equal<T, T2: Equatable>(to value: T, type: T2.Type) -> ParameterMatcher<T> {
    return equal(to: value) { $0 as! T2 == $1 as! T2 }
}

extension XCTestCase {

    func waitForMainQueue(queue: DispatchQueue = DispatchQueue.main) {
        let e = expectation(description: "Wait for Main Queue")
        queue.async { e.fulfill() }
        waitForExpectations(timeout: 2)
    }

}

extension ECPoint: Equatable {

    public static func == (lhs: ECPoint, rhs: ECPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

}

extension KeccakDigest: Equatable {

    public static func == (lhs: KeccakDigest, rhs: KeccakDigest) -> Bool {
        return lhs.digest() == rhs.digest()
    }

}

extension HelloMessage {

    convenience init(capabilities: [Capability] = []) {
        self.init(nodeId: Data(), port: 0, capabilities: capabilities)
    }

}

extension DisconnectMessage {

    convenience init() {
        self.init(reason: .bad_protocol)
    }

}

extension GetProofsMessage {

    convenience init() {
        self.init(requestId: 0, blockHash: Data(), key: Data())
    }

}

extension StatusMessage {

    convenience init(protocolVersion: Int = 0, networkId: Int = 0, genesisHash: Data = Data(), headHeight: Int = 0) {
        self.init(
                protocolVersion: protocolVersion,
                networkId: networkId,
                genesisHash: genesisHash,
                headTotalDifficulty: 0,
                headHash: Data(),
                headHeight: headHeight
        )
    }

}

extension BlockHeadersMessage {

    convenience init(requestId: Int = 0, headers: [BlockHeader] = []) {
        self.init(requestId: requestId, bv: 0, headers: headers)
    }

}

extension ProofsMessage {

    convenience init(requestId: Int = 0) {
        self.init(requestId: requestId, bv: 0, nodes: [])
    }

}

extension AnnounceMessage {

    convenience init(lastBlockHash: Data = Data(), lastBlockHeight: Int = 0) {
        self.init(blockHash: lastBlockHash, blockTotalDifficulty: 0, blockHeight: lastBlockHeight, reorganizationDepth: 0)
    }

}

extension BlockHeader: Equatable {

    convenience init(hashHex: Data = Data(repeating: 7, count: 10), parentHash: Data = Data(repeating: 8, count: 10), totalDifficulty: BigUInt = 0, height: Int = 0) {
        self.init(
                hashHex: hashHex,
                totalDifficulty: totalDifficulty,
                parentHash: Data(),
                unclesHash: Data(),
                coinbase: Data(),
                stateRoot: Data(),
                transactionsRoot: Data(),
                receiptsRoot: Data(),
                logsBloom: Data(),
                difficulty: 0,
                height: height,
                gasLimit: 0,
                gasUsed: 0,
                timestamp: 0,
                extraData: Data(),
                mixHash: Data(),
                nonce: Data()
        )
    }

    public static func == (lhs: BlockHeader, rhs: BlockHeader) -> Bool {
        return lhs.hashHex == rhs.hashHex
    }

}

extension AccountStateSpv {

    convenience init(address: Data = Data()) {
        self.init(address: address, nonce: 0, balance: 0, storageHash: Data(), codeHash: Data())
    }

}

//extension RawTransaction {
//
//    convenience init(wei: String = "1") {
//        self.init(wei: wei, to: "", gasPrice: 0, gasLimit: 0, nonce: 0)
//    }
//
//}

extension Node: Equatable {

    static public func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs.id == rhs.id && lhs.discoveryPort == rhs.discoveryPort
    }

}

extension NodeRecord: Equatable {

    static public func ==(lhs: NodeRecord, rhs: NodeRecord) -> Bool {
        return lhs.id == rhs.id && lhs.discoveryPort == rhs.discoveryPort &&
                lhs.used == rhs.used && lhs.eligible == rhs.eligible
    }

}

extension Socket.Address: Equatable {

    static public func ==(lhs: Socket.Address, rhs: Socket.Address) -> Bool {
        return lhs.family == rhs.family && lhs.size == rhs.size
    }

}

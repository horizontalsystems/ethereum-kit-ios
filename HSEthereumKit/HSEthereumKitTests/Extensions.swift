import XCTest
import Cuckoo
@testable import HSEthereumKit
@testable import HSCryptoKit

class TestError: Error {}

func equal<T, T2: AnyObject>(to value: T, type: T2.Type) -> ParameterMatcher<T> {
    return equal(to: value) { $0 as! T2 === $1 as! T2 }
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
        self.init(peerId: Data(), port: 0, capabilities: capabilities)
    }

}

extension DisconnectMessage {

    convenience init() {
        self.init(reason: .bad_protocol)
    }

}

extension GetBlockHeadersMessage {

    convenience init() {
        self.init(requestId: 0, blockHash: Data())
    }

}

extension GetProofsMessage {

    convenience init() {
        self.init(requestId: 0, blockHash: Data(), key: Data())
    }

}

extension StatusMessage {

    convenience init() {
        self.init(
                protocolVersion: 0,
                networkId: 0,
                genesisHash: Data(),
                headTotalDifficulty: Data(),
                headHash: Data(),
                headHeight: 0
        )
    }

}

extension BlockHeadersMessage {

    convenience init(headers: [BlockHeader] = []) {
        self.init(requestId: 0, bv: 0, headers: headers)
    }

}

extension BlockHeader: Equatable {

    convenience init(hashHex: Data = Data(repeating: 7, count: 10), totalDifficulty: Data = Data(), height: BInt = 0) {
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
                difficulty: Data(),
                height: height,
                gasLimit: Data(),
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

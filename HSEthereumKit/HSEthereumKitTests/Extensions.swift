import XCTest
import Cuckoo
@testable import HSEthereumKit
@testable import HSCryptoKit

class TestError: Error {}

func equal<T, T2: AnyObject>(to value: T, type: T2.Type) -> ParameterMatcher<T> {
    return equal(to: value) { $0 as! T2 === $1 as! T2 }
}

func equal<T, T2: Equatable>(to value: T, type: T2.Type) -> ParameterMatcher<T> {
    return equal(to: value) { $0 as! T2 == $1 as! T2 }
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

extension GetBlockHeadersMessage {

    convenience init() {
        self.init(requestId: 0, blockHash: Data(), maxHeaders: 0)
    }

}

extension GetProofsMessage {

    convenience init() {
        self.init(requestId: 0, blockHash: Data(), key: Data())
    }

}

extension StatusMessage {

    convenience init(protocolVersion: Int = 0, networkId: Int = 0, genesisHash: Data = Data(), headHeight: BInt = 0) {
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

    convenience init(lastBlockHash: Data = Data(), lastBlockHeight: BInt = 0) {
        self.init(blockHash: lastBlockHash, blockTotalDifficulty: 0, blockHeight: lastBlockHeight, reorganizationDepth: 0)
    }

}

extension BlockHeader: Equatable {

    convenience init(hashHex: Data = Data(repeating: 7, count: 10), totalDifficulty: BInt = 0, height: BInt = 0) {
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

extension AccountState {

    convenience init() {
        self.init(address: Data(), nonce: 0, balance: Balance(wei: 0), storageHash: Data(), codeHash: Data())
    }

}

extension FeePriority: Equatable {
    public static func == (lhs: FeePriority, rhs: FeePriority) -> Bool {
        switch (lhs, rhs) {
        case (.lowest, .lowest): return true
        case (.low, .low): return true
        case (.medium, .medium): return true
        case (.high, .high): return true
        case (.highest, .highest): return true
        case (.custom(let lhsGasPriceInWei), .custom(let rhsGasPriceInWei)): return lhsGasPriceInWei == rhsGasPriceInWei
        default: return false
        }
    }
}

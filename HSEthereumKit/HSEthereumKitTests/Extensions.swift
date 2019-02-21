import XCTest
@testable import HSEthereumKit
@testable import HSCryptoKit

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
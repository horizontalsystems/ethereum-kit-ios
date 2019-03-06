import XCTest
import Cuckoo
@testable import HSEthereumKit
@testable import HSCryptoKit

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

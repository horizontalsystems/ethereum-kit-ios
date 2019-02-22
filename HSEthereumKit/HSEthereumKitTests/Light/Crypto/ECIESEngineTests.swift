import XCTest
import Cuckoo
@testable import HSEthereumKit

class ECIESEngineTests: XCTestCase {
    private var crypto: MockIECIESCrypto!
    private var eciesEngine: ECIESEngine!

    override func setUp() {
        super.setUp()

        crypto = MockIECIESCrypto()
        eciesEngine = ECIESEngine()
    }

    override func tearDown() {
        crypto = nil
        eciesEngine = nil

        super.tearDown()
    }

    func testEncrypt() {

    }

}

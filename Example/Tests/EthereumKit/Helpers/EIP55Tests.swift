import XCTest
//import Cuckoo
@testable import EthereumKit

class EIP55Tests: XCTestCase {

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
    func testIgnoreFormatAddress() {
        let notChanged = [
            "",
            "0x0000",
            "0xRj709f2102306220921060314715629080e2Fb77"
        ]
        notChanged.forEach { address in
            XCTAssertEqual(EIP55.format(address: address), address)
        }
    }

    func testFormatNormalAddress() {
        let validAddresses = [
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
            "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"
        ]

        validAddresses.forEach { address in
            XCTAssertEqual(EIP55.format(address: address.lowercased()), address)
            XCTAssertEqual(EIP55.format(address: "0x" + address.dropFirst(2).uppercased()), address)
        }
    }

    func testFormatAddressWithoutPrefix() {
        let address = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
        XCTAssertEqual(EIP55.format(address: "5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed".lowercased()), address)
    }

}

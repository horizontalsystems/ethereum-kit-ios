import XCTest
//import Cuckoo
@testable import EthereumKit

class AddressValidatorTests: XCTestCase {
    private var addressValidator: AddressValidator!

    override func setUp() {
        super.setUp()

        addressValidator = AddressValidator()
    }

    override func tearDown() {
        addressValidator = nil

        super.tearDown()
    }

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
    func testValidAddress() {
        let invalidAddresses = [
            ("0x0000", AddressValidator.ValidationError.invalidAddressLength),
            ("0xrj709f2102306220921060314715629080e2fb77", AddressValidator.ValidationError.invalidSymbols),
            ("1x52908400098527886E0F7030069857D2E4169EE7", AddressValidator.ValidationError.wrongAddressPrefix),
            ("0x52908400098527886e0F7030069857D2e4169eE7", AddressValidator.ValidationError.invalidChecksum)
        ]
        invalidAddresses.forEach { address, error in
            testInvalid(address: address, expectedError: error)
        }

        let validAddresses = [                              // All caps
            "0x52908400098527886E0F7030069857D2E4169EE7",
            "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
                                                            // All Lower
            "0xde709f2102306220921060314715629080e2fb77",
            "0x27b1fdb04752bbc536007a920d24acb045561c26",
                                                            // Normal
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
            "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"
        ]

        validAddresses.forEach { testValid(address: $0) }
    }

    func testValid(address: String) {
        do {
            try addressValidator.validate(address: address)
        } catch {
            XCTFail("Error \(error) Handled!")
        }
    }

    func testInvalid(address: String, expectedError: Error) {
        do {
            try addressValidator.validate(address: address)
            XCTFail("Error Not Handled!")
        } catch let error as AddressValidator.ValidationError {
            XCTAssertEqual(error, expectedError as! AddressValidator.ValidationError)
        } catch {
            XCTFail("Unexpected Error Handled")
        }
    }

}

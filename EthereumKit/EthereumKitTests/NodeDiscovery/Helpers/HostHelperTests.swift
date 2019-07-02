import XCTest
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class HostHelperTests: QuickSpec {

    override func spec() {

        let testWrongStrings: [String] = [
            "123",
            "12.13.14",
            "12.13.14.257",
            "someError",
        ]
        describe("#decode(host: String)") {
            it("checks right host") {
                expect(HostHelper.decode(host: "1.2.3.4")).to(equal(Data([0x01, 0x02, 0x03, 0x04])))
            }
            it("checks wrong host data") {
                testWrongStrings.forEach { key in
                    expect(HostHelper.decode(host: key)).to(beNil())
                }
            }
        }
        describe("#encode(host: String)") {
            it("checks right host") {
                expect(HostHelper.encode(host: Data([0x01, 0x02, 0x03, 0x04]))).to(equal("1.2.3.4"))
            }
            it("checks host data count different then 4") {
                expect(HostHelper.encode(host: Data([0x01]))).to(beNil())
            }
        }
    }

}

import XCTest
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class CapabilityHelperTests: QuickSpec {

    override func spec() {
        let les1 = Capability(name: "les", version: 1)
        let les2 = Capability(name: "les", version: 2)
        let eth1 = Capability(name: "eth", version: 1)
        let pip1 = Capability(name: "pip", version: 1)

        let helper = CapabilityHelper()

        describe("#sharedCapabilities") {
            it("returns empty when there are no intersections by name and version") {
                let result = helper.sharedCapabilities(myCapabilities: [les1], nodeCapabilities: [les2, eth1])
                expect(result).to(beEmpty())
            }

            it("returns intersections by name and version") {
                let result = helper.sharedCapabilities(myCapabilities: [les1, eth1], nodeCapabilities: [eth1])
                expect(result).to(equal([eth1]))
            }

            it("returns sorted intersections by name") {
                let result = helper.sharedCapabilities(myCapabilities: [les1, eth1], nodeCapabilities: [pip1, les1, eth1])
                expect(result).to(equal([eth1, les1]))
            }

            it("returns only latest version intersection if there are several capabilities for same name") {
                let result = helper.sharedCapabilities(myCapabilities: [les1, les2, eth1], nodeCapabilities: [pip1, les1, les2, eth1])
                expect(result).to(equal([eth1, les2]))
            }
        }
    }

}

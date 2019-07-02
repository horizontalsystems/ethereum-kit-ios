import XCTest
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class NodeParserTests: QuickSpec {

//  expected format : enode://<hex node id>@10.3.58.6:30303?discport=30301
    override func spec() {
        let parser = NodeParser()

        let nodeUriStart = "enode://"
        let nodeId = "01020304ABCDEF"
        let nodeIdData = Data(hex: "01020304ABCDEF")!

        let testData = [
            "01020304ABCDEF": Node(id: nodeIdData, host: "", port: 0, discoveryPort: 0),
            "01020304ABCDEF@test-host": Node(id: nodeIdData, host: "", port: 0, discoveryPort: 0),
            "01020304ABCDEF@12.12": Node(id: nodeIdData, host: "12.12", port: 0, discoveryPort: 0),
            "01020304ABCDEF@12.12?discport=123": Node(id: nodeIdData, host: "12.12", port: 0, discoveryPort: 123),
            "01020304ABCDEF@12.12?discport=12a3": Node(id: nodeIdData, host: "12.12", port: 0, discoveryPort: 0),
            "01020304ABCDEF@12.12:123": Node(id: nodeIdData, host: "12.12", port: 123, discoveryPort: 0),
            "01020304ABCDEF@12.12:12a3": Node(id: nodeIdData, host: "12.12", port: 0, discoveryPort: 0),
            "01020304ABCDEF@12.12:123?discport=456": Node(id: nodeIdData, host: "12.12", port: 123, discoveryPort: 456),
            "01020304ABCDEF@12.12:12a3?discport=4a56": Node(id: nodeIdData, host: "12.12", port: 0, discoveryPort: 0),
        ]

        context("when uri hasn't node id") {
            it("returns exception") {
                expect { try parser.parse(uri: nodeUriStart) }.to(throwError(NodeParsingError.emptyNodeId))
                expect { try parser.parse(uri: "") }.to(throwError(NodeParsingError.emptyNodeId))
            }
        }
        context("when node id has wrong symbols") {
            it("returns exception") {
                expect { try parser.parse(uri: "abfer3234") }.to(throwError(NodeParsingError.wrongNodeId))
            }
        }
        context("when uri iterate by right test data") {
            it("returns Node with different values") {
                testData.forEach { (uri: String, nod: Node) in
                    expect { try parser.parse(uri: uri) }.to(equal(nod))
                }
            }
            it("returns Node with id only ignored enode://") {
                let expectNode = Node(id: Data(hex: nodeId)!, host: "", port: 0, discoveryPort: 0)
                expect { try parser.parse(uri: nodeUriStart + nodeId) }.to(equal(expectNode))
            }
        }
    }

}

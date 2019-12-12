import XCTest
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class NodeManagerTests: QuickSpec {

    override func spec() {
        let mockStorage = MockIDiscoveryStorage()
        let mockDiscovery = MockINodeDiscovery()
        let mockFactory = MockINodeFactory()
        let mockDelegate = MockINodeManagerDelegate()

        let state = NodeManagerState()
        let manager = NodeManager(storage: mockStorage, nodeDiscovery: mockDiscovery, nodeFactory: mockFactory, state: state)

        let nodeId = Data(repeating: 2, count: 64)
        let nodeHost = "host"
        let port = 1
        let discPort = 2

        afterEach {
            reset(mockStorage, mockDiscovery, mockDelegate, mockFactory)
        }

        describe("#node") {
            context("empty leastScoreNode") {
                beforeEach {
                    stub(mockStorage) { mock in
                        when(mock.leastScoreNode(excludingIds: equal(to: []))).thenReturn(nil)
                    }
                    state.removeAll()
                }
                it("it checks already processing and stop working") {
                    stub(mockDiscovery) { mock in
                        when(mock.processing.get).thenReturn(true)
                    }
                    let node = manager.node
                    expect(node).to(beNil())
                    expect(state.usedIds).to(beEmpty())

                    verify(mockDiscovery).processing.get()
                    verifyNoMoreInteractions(mockDiscovery)
                }
                it("it checks not processing and call lookup") {
                    stub(mockDiscovery) { mock in
                        when(mock.processing.get).thenReturn(false)
                        when(mock.lookup()).thenDoNothing()
                    }
                    let node = manager.node
                    expect(node).to(beNil())
                    expect(state.usedIds).to(beEmpty())

                    verify(mockDiscovery).processing.get()
                    verify(mockDiscovery).lookup()
                }
            }
            context("return node") {
                let node = Node(id: nodeId, host: nodeHost, port: port, discoveryPort: discPort)
                let nodeRecord = NodeRecord(id: nodeId, host: nodeHost, port: port, discoveryPort: discPort, used: false, eligible: false, score: 0, timestamp: 0)

                beforeEach {
                    stub(mockFactory) { mock in
                        when(mock.node(id: equal(to: nodeId), host: nodeHost, port: port, discoveryPort: discPort)).thenReturn(node)
                    }
                    stub(mockStorage) { mock in
                        when(mock.leastScoreNode(excludingIds: equal(to: []))).thenReturn(nodeRecord)
                    }
                }
                it("adds id to state and return node") {
                    let node = manager.node
                    expect(node!.id).to(equal(nodeRecord.id))
                    expect(state.usedIds).to(equal([nodeRecord.id]))
                    expect(node!.host).to(equal(nodeHost))
                    expect(node!.port).to(equal(port))
                    expect(node!.discoveryPort).to(equal(discPort))
                }
            }
        }
        describe("#markSuccess|Failed(id: Data)") {
            let disconnectedId = Data([1, 2])

            beforeEach {
                stub(mockStorage) { mock in
                    when(mock.increasePeerAddressScore(id: equal(to: disconnectedId))).thenDoNothing()
                }
                state.removeAll()
                state.add(usedId: disconnectedId)
            }
            it("removes from state and update node score") {
                manager.markSuccess(id: disconnectedId)

                expect(state.usedIds).to(equal([]))
                verify(mockStorage).increasePeerAddressScore(id: equal(to: disconnectedId))
                verifyNoMoreInteractions(mockStorage)
            }
            it("removes from state and set nonEligible for node") {
                manager.markSuccess(id: disconnectedId)

                expect(state.usedIds).to(equal([]))
                verify(mockStorage).increasePeerAddressScore(id: equal(to: disconnectedId))
                verifyNoMoreInteractions(mockStorage)
            }
        }
        describe("#add(nodes:)") {
            it("stops when array is empty") {
                manager.add(nodes: [])
                verifyNoMoreInteractions(mockStorage)
                verifyNoMoreInteractions(mockDelegate)
            }
            context("add node") {
                let node = Node(id: nodeId, host: nodeHost, port: port, discoveryPort: discPort)
                let nodeRecord = NodeRecord(id: nodeId, host: nodeHost, port: port, discoveryPort: discPort, used: false, eligible: true, score: 0, timestamp: 0)
                beforeEach {
                    stub(mockStorage) { mock in
                        when(mock.save(nodes: equal(to: [nodeRecord]))).thenDoNothing()
                    }
                }
                it("call storage save method") {
                    stub(mockFactory) { mock in
                        when(mock.newNodeRecord(id: equal(to: nodeId), host: equal(to: nodeHost), port: port, discoveryPort: discPort)).thenReturn(nodeRecord)
                    }
                    manager.add(nodes: [node])

                    verify(mockFactory).newNodeRecord(id: equal(to: nodeId), host: equal(to: nodeHost), port: port, discoveryPort: discPort)
                    verify(mockStorage).save(nodes: equal(to: [nodeRecord]))

                    verifyNoMoreInteractions(mockFactory)
                    verifyNoMoreInteractions(mockStorage)
                }
            }
        }
    }

}

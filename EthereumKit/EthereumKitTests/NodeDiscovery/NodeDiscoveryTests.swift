import XCTest
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class NodeDiscoveryTests: QuickSpec {

    override func spec() {
        let privKey = Data([0x01])
        let nodeId = Data(repeating: 1, count: 64)
        let ecKey = ECKey(privateKey: privKey, publicKeyPoint: ECPoint(nodeId: nodeId))
        let mockDiscoveryStorage = MockIDiscoveryStorage()
        let mockClient = MockIUdpClient()
        let mockFactory = MockIUdpFactory()
        let mockNodeParser = MockINodeParser()
        let mockPacketParser = MockIPacketParser()
        let mockManager = MockINodeManager()

        let selfNode = Node(id: nodeId, host: NodeDiscovery.selfHost, port: NodeDiscovery.selfPort, discoveryPort: NodeDiscovery.selfPort)
        let node = Node(id: Data(repeating: 2, count: 64), host: "host", port: 1, discoveryPort: 2)
        let nodeRecord = NodeRecord(id: Data(repeating: 2, count: 64), host: "host", port: 1, discoveryPort: 2, used: false, eligible: false, score: 1, timestamp: 10)

        let state = NodeDiscoveryState()
        let discovery = NodeDiscovery(ecKey: ecKey, factory: mockFactory, discoveryStorage: mockDiscoveryStorage, state: state, nodeParser: mockNodeParser, packetParser: mockPacketParser)
        discovery.nodeManager = mockManager

        afterEach {
            reset(mockDiscoveryStorage, mockClient, mockFactory, mockNodeParser, mockPacketParser, mockManager)
        }

        describe("#lookup") {
            context("get node from storage") {
                it("throws error when first time return nil") {
                    stub(mockDiscoveryStorage) { mock in
                        when(mock.nonUsedNode()).thenReturn(nil)
                    }
                    do {
                        try discovery.lookup()
                    } catch let error as DiscoveryError {
                        XCTAssertEqual(error, DiscoveryError.allNodesUsed)
                    } catch {
                        XCTFail("Unexpected error!")
                    }

                    verify(mockDiscoveryStorage).nonUsedNode()
                    verifyNoMoreInteractions(mockDiscoveryStorage)
                }
                context("make node used and start find neighbors") {
                    beforeEach {
                        stub(mockDiscoveryStorage) { mock in
                            when(mock.nonUsedNode()).thenReturn(nodeRecord)
                            when(mock.setUsed(node: equal(to: nodeRecord))).thenDoNothing()
                        }
                    }
                    it("can't creates client") {
                        stub(mockFactory) { mock in
                            when(mock.client(node: equal(to: node), timeoutInterval: NodeDiscovery.timeoutInterval)).thenThrow(UDPClientError.cantCreateAddress)
                        }
                        do {
                            try discovery.lookup()
                        } catch let error as UDPClientError {
                            XCTAssertEqual(error, UDPClientError.cantCreateAddress)
                        } catch {
                            XCTFail("Unexpected error!")
                        }
                        verify(mockDiscoveryStorage).nonUsedNode()
                        verify(mockDiscoveryStorage).setUsed(node: equal(to: nodeRecord))
                        verify(mockFactory).client(node: equal(to: node), timeoutInterval: NodeDiscovery.timeoutInterval)
                        verifyNoMoreInteractions(mockDiscoveryStorage)
                        verifyNoMoreInteractions(mockFactory)
                    }
                    context("success create client") {
                        beforeEach {
                            stub(mockFactory) { mock in
                                when(mock.client(node: equal(to: node), timeoutInterval: NodeDiscovery.timeoutInterval)).thenReturn(mockClient)
                            }
                            stub(mockClient) { mock in
                                when(mock.delegate.set(any())).thenDoNothing()
                                when(mock.listen()).thenDoNothing()
                            }
                        }
                        it("throws error on create pingData") {
                            stub(mockFactory) { mock in
                                when(mock.pingData(from: equal(to: selfNode), to: equal(to: node), expiration: NodeDiscovery.expirationInterval)).thenThrow(PackageSerializeError.wrongSerializer)
                            }
                            do {
                                try discovery.lookup()
                            } catch let error as PackageSerializeError {
                                XCTAssertEqual(error, PackageSerializeError.wrongSerializer)
                            } catch {
                                XCTFail("Unexpected error!")
                            }

                            verify(mockClient).delegate.set(any())
                            verify(mockClient).listen()
                            verify(mockFactory).pingData(from: equal(to: selfNode), to: equal(to: node), expiration: NodeDiscovery.expirationInterval)
                            verify(mockClient, never()).send(any())
                        }
                        context("success create pingData") {
                            let pingData = Data(repeating: 9, count: 2)
                            beforeEach {
                                stub(mockFactory) { mock in
                                    when(mock.pingData(from: equal(to: selfNode), to: equal(to: node), expiration: NodeDiscovery.expirationInterval)).thenReturn(pingData)
                                }
                            }
                            it("throws error on send pingData") {
                                stub(mockClient) { mock in
                                    when(mock.send(equal(to: pingData))).thenThrow(UDPClientError.cantCreateAddress)
                                }
                                do {
                                    try discovery.lookup()
                                } catch let error as UDPClientError {
                                    XCTAssertEqual(error, UDPClientError.cantCreateAddress)
                                } catch {
                                    XCTFail("Unexpected error!")
                                }
                                verify(mockClient).send(equal(to: pingData))
                                verify(mockFactory, never()).findNodeData(target: any(), expiration: any())
                            }
                            context("success send pingData") {
                                beforeEach {
                                    stub(mockClient) { mock in
                                        when(mock.send(equal(to: pingData))).thenDoNothing()
                                    }
                                }
                                it("throws error on create findNodeData") {
                                    stub(mockFactory) { mock in
                                        when(mock.findNodeData(target: equal(to: nodeId), expiration: equal(to: NodeDiscovery.expirationInterval))).thenThrow(PackageSerializeError.wrongSerializer)
                                    }
                                    do {
                                        try discovery.lookup()
                                    } catch let error as PackageSerializeError {
                                        XCTAssertEqual(error, PackageSerializeError.wrongSerializer)
                                    } catch {
                                        XCTFail("Unexpected error!")
                                    }

                                    verify(mockFactory).findNodeData(target: equal(to: nodeId), expiration: equal(to: NodeDiscovery.expirationInterval))
                                    // send only ping packet
                                    verify(mockClient, times(1)).send(any())
                                }
                            }
                            context("success create findNodeData") {
                                let findNodeData = Data(repeating: 8, count: 2)
                                beforeEach {
                                    stub(mockFactory) { mock in
                                        when(mock.findNodeData(target: equal(to: nodeId), expiration: equal(to: NodeDiscovery.expirationInterval))).thenReturn(findNodeData)
                                    }
                                    stub(mockClient) { mock in
                                        when(mock.send(equal(to: pingData))).thenDoNothing()
                                        when(mock.send(equal(to: findNodeData))).thenDoNothing()
                                    }
                                }
                                it("sends findNodeData and goes to second iteration with error AllNodesUsed") {
                                    stub(mockDiscoveryStorage) { mock in
                                        when(mock.nonUsedNode()).thenReturn(nodeRecord).thenReturn(nil)
                                    }

                                    do {
                                        try discovery.lookup()
                                    } catch let error as DiscoveryError {
                                        XCTAssertEqual(error, DiscoveryError.allNodesUsed)
                                    } catch {
                                        XCTFail("Unexpected error!")
                                    }
                                    verify(mockClient).send(equal(to: findNodeData))
                                }
                                it("success get nodes and send to all alpha-count nodes") {
                                    stub(mockDiscoveryStorage) { mock in
                                        when(mock.nonUsedNode()).thenReturn(nodeRecord)
                                    }

                                    do {
                                        try discovery.lookup()
                                    } catch {
                                        XCTFail("Unexpected error!")
                                    }
                                    verify(mockClient, times(NodeDiscovery.alpha)).send(equal(to: findNodeData))
                                }
                            }
                        }
                    }
                }
            }
        }
        describe("didStop(client, by error)") {
            let error = TestError()
            beforeEach {
                stub(mockDiscoveryStorage) { mock in
                    when(mock.remove(node: equal(to: node))).thenDoNothing()
                }
                stub(mockClient) { mock in
                    when(mock.delegate.set(any())).thenDoNothing()
                    when(mock.noResponse.get).thenReturn(true)
                    when(mock.node.get).thenReturn(node)
                    when(mock.id.get).thenReturn(node.id)
                }
                state.removeAll()
                state.add(client: mockClient)
            }
            it("remove client from db if not any response") {
                discovery.didStop(mockClient, by: error)

                verify(mockDiscoveryStorage).remove(node: equal(to: node))
                expect(state.clients).to(beEmpty())
            }
            it("remove client only from state if it responses previously") {
                stub(mockClient) { mock in
                    when(mock.noResponse.get).thenReturn(false)
                }
                discovery.didStop(mockClient, by: error)

                verify(mockDiscoveryStorage, never()).remove(node: equal(to: node))
                expect(state.clients).to(beEmpty())
            }
        }
        describe("#didReceive(client:data)") {
            let data = Data([0x01])
            let hash = Data(repeating: 3, count: 2)
            let sig = Data(repeating: 4, count: 2)

            context("receive any wrong packet") {
                stub(mockPacketParser) { mock in
                    when(mock.parse(data: equal(to: data))).thenThrow(PacketParseError.tooSmall)
                }

                do {
                    try discovery.didReceive(mockClient, data: data)
                } catch {
                    XCTFail("Unexpected error!")
                }

                verifyNoMoreInteractions(mockClient)
                verifyNoMoreInteractions(mockFactory)
                verifyNoMoreInteractions(mockManager)
            }
            it("can't cast packet") {
                let package = FindNodePackage(target: hash, expiration: Int32(NodeDiscovery.expirationInterval))
                let packet = Packet(hash: hash, signature: sig, type: 1, package: package)
                stub(mockPacketParser) { mock in
                    when(mock.parse(data: equal(to: data))).thenReturn(packet)
                }
                do {
                    try discovery.didReceive(mockClient, data: data)
                } catch let error as PacketParseError {
                    XCTAssertEqual(error, PacketParseError.wrongType)
                } catch {
                    XCTFail("Unexpected error!")
                }
            }
            context("receive ping packet") {
                let package = PingPackage(from: node, to: selfNode, expiration: Int32(NodeDiscovery.expirationInterval))
                let packet = Packet(hash: hash, signature: sig, type: 1, package: package)
                beforeEach {
                    stub(mockPacketParser) { mock in
                        when(mock.parse(data: equal(to: data))).thenReturn(packet)
                    }
                }
                it("throws error on create pongData") {
                    stub(mockFactory) { mock in
                        when(mock.pongData(to: equal(to: node), hash: equal(to: hash), expiration: NodeDiscovery.expirationInterval)).thenThrow(PackageSerializeError.wrongSerializer)
                    }
                    do {
                        try discovery.didReceive(mockClient, data: data)
                    } catch let error as PackageSerializeError {
                        XCTAssertEqual(error, PackageSerializeError.wrongSerializer)
                    } catch {
                        XCTFail("Unexpected error!")
                    }

                    verify(mockFactory).pongData(to: equal(to: node), hash: equal(to: hash), expiration: NodeDiscovery.expirationInterval)
                    verify(mockClient, never()).send(any())
                }
                context("success create pongData") {
                    let pongData = Data(repeating: 9, count: 2)
                    beforeEach {
                        stub(mockFactory) { mock in
                            when(mock.pongData(to: equal(to: node), hash: equal(to: hash), expiration: NodeDiscovery.expirationInterval)).thenReturn(pongData)
                        }
                    }
                    it("throws error on send pongData") {
                        stub(mockClient) { mock in
                            when(mock.send(equal(to: pongData))).thenThrow(UDPClientError.cantCreateAddress)
                        }
                        do {
                            try discovery.didReceive(mockClient, data: data)
                        } catch let error as UDPClientError {
                            XCTAssertEqual(error, UDPClientError.cantCreateAddress)
                        } catch {
                            XCTFail("Unexpected error!")
                        }
                        verify(mockClient).send(equal(to: pongData))
                        verify(mockFactory, never()).findNodeData(target: any(), expiration: any())
                    }
                    context("success send pongData") {
                        beforeEach {
                            stub(mockClient) { mock in
                                when(mock.send(equal(to: pongData))).thenDoNothing()
                            }
                        }
                        it("throws error on create findNodeData") {
                            stub(mockFactory) { mock in
                                when(mock.findNodeData(target: equal(to: nodeId), expiration: equal(to: NodeDiscovery.expirationInterval))).thenThrow(PackageSerializeError.wrongSerializer)
                            }
                            do {
                                try discovery.didReceive(mockClient, data: data)
                            } catch let error as PackageSerializeError {
                                XCTAssertEqual(error, PackageSerializeError.wrongSerializer)
                            } catch {
                                XCTFail("Unexpected error!")
                            }

                            verify(mockFactory).findNodeData(target: equal(to: nodeId), expiration: equal(to: NodeDiscovery.expirationInterval))
                            verify(mockClient).send(any())
                        }
                    }
                    context("success create findNodeData") {
                        let findNodeData = Data(repeating: 8, count: 2)
                        beforeEach {
                            stub(mockFactory) { mock in
                                when(mock.findNodeData(target: equal(to: nodeId), expiration: equal(to: NodeDiscovery.expirationInterval))).thenReturn(findNodeData)
                            }
                            stub(mockClient) { mock in
                                when(mock.send(equal(to: pongData))).thenDoNothing()
                                when(mock.send(equal(to: findNodeData))).thenDoNothing()
                            }
                        }
                        it("sends findNodeData") {
                            stub(mockDiscoveryStorage) { mock in
                                when(mock.nonUsedNode()).thenReturn(nodeRecord).thenReturn(nil)
                            }

                            do {
                                try discovery.didReceive(mockClient, data: data)
                            } catch {
                                XCTFail("Unexpected error!")
                            }

                            verify(mockClient).send(equal(to: findNodeData))
                        }
                        it("success get nodes") {
                            stub(mockDiscoveryStorage) { mock in
                                when(mock.nonUsedNode()).thenReturn(nodeRecord)
                            }

                            do {
                                try discovery.didReceive(mockClient, data: data)
                            } catch {
                                XCTFail("Unexpected error!")
                            }
                            verify(mockClient).send(equal(to: findNodeData))
                        }
                    }
                }
            }
            context("receive Neighbors") {
                let expectedNode = Node(id: Data([1, 2, 3]), host: "host", port: 9, discoveryPort: 10)
                let package = NeighborsPackage(nodes: [expectedNode], expiration: Int32(NodeDiscovery.expirationInterval))
                let packet = Packet(hash: hash, signature: sig, type: 4, package: package)
                beforeEach {
                    stub(mockPacketParser) { mock in
                        when(mock.parse(data: equal(to: data))).thenReturn(packet)
                    }
                }
                it("calls nodeManager add nodes") {
                    stub(mockManager) { mock in
                        when(mock.add(nodes: equal(to: [expectedNode]))).thenDoNothing()
                    }

                    do {
                        try discovery.didReceive(mockClient, data: data)
                    } catch {
                        XCTFail("Unexpected error!")
                    }
                    verify(mockManager).add(nodes: equal(to: [expectedNode]))
                }
            }
        }
    }

}

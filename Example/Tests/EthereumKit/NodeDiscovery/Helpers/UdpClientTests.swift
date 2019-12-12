import XCTest
import Quick
import Nimble
import Cuckoo
import Socket

@testable import EthereumKit

class UdpClientTests: QuickSpec {

    override func spec() {
        let mockSocket = MockIUdpSocket()
        let node = Node(id: Data([0x01]), host: "1.2.3.4", port: 1, discoveryPort: 2)
        let timeoutInterval: TimeInterval = 5
        let mockDelegate = MockIUdpClientDelegate()

        let client = try! UdpClient(socket: mockSocket, node: node, timeoutInterval: timeoutInterval, queue: DispatchQueue.main)
        client.delegate = mockDelegate

        let error = TestError()

        afterEach {
            reset(mockSocket, mockDelegate)
        }

        describe("#listen()") {
            context("socket can't change timeout") {
                it("send didStop to delegate and stop working") {
                    stub(mockSocket) { mock in
                        when(mock.setReadTimeout(value: UInt(timeoutInterval))).thenThrow(error)
                    }
                    stub(mockDelegate) { mock in
                        when(mock.didStop(_: equal(to: client, equalWhen: { $0 === $1 }), by: any())).thenDoNothing()
                    }
                    client.listen()
                    self.waitForMainQueue()

                    verify(mockSocket).setReadTimeout(value: UInt(timeoutInterval))
                    verify(mockDelegate).didStop(_: equal(to: client, equalWhen: { $0 === $1 }), by: equal(to: error, type: TestError.self))

                    verifyNoMoreInteractions(mockSocket)
                }
            }
            context("success set timeout") {
                beforeEach {
                    stub(mockSocket) { mock in
                        when(mock.setReadTimeout(value: UInt(timeoutInterval))).thenDoNothing()
                    }
                }
                it("stops if read datagramm error") {
                    stub(mockDelegate) { mock in
                        when(mock.didStop(_: equal(to: client, equalWhen: { $0 === $1 }), by: any())).thenDoNothing()
                    }
                    stub(mockSocket) { mock in
                        when(mock.readDatagram()).thenThrow(error)
                    }
                    client.listen()
                    self.waitForMainQueue()

                    verify(mockSocket).readDatagram()
                    verify(mockDelegate).didStop(_: equal(to: client, equalWhen: { $0 === $1 }), by: equal(to: error, type: TestError.self))

                    verifyNoMoreInteractions(mockDelegate)
                }
                context("if readDatagram return empty data") {
                    beforeEach {
                        stub(mockSocket) { mock in
                            when(mock.setReadTimeout(value: UInt(timeoutInterval))).thenDoNothing()
                        }
                        stub(mockDelegate) { mock in
                            when(mock.didStop(_: equal(to: client, equalWhen: { $0 === $1 }), by: any())).thenDoNothing()
                        }
                    }
                    it("stops and send timeout error") {
                        stub(mockSocket) { mock in
                            when(mock.readDatagram()).thenReturn((0, Data()))
                        }
                        let timeoutError = UDPClientError.timeout

                        client.listen()
                        self.waitForMainQueue()

                        expect(client.noResponse).to(equal(true))
                        verify(mockDelegate).didStop(_: equal(to: client, equalWhen: { $0 === $1 }), by: equal(to: timeoutError, type: UDPClientError.self))
                        verifyNoMoreInteractions(mockDelegate)
                    }
                    context("when read success data") {
                        beforeEach {
                            stub(mockSocket) { mock in
                                when(mock.readDatagram()).thenReturn((1, Data([0x01]))).thenReturn((0, Data()))
                            }
                            stub(mockDelegate) { mock in
                                when(mock.didReceive(_: equal(to: client, equalWhen: { $0 === $1 }), data: equal(to: Data([0x01])))).thenDoNothing()
                            }
                        }
                        it("call didReceive method and go next iteration") {
                            client.listen()
                            self.waitForMainQueue()

                            expect(client.noResponse).to(equal(false))
                            verify(mockDelegate).didReceive(_: equal(to: client, equalWhen: { $0 === $1 }), data: equal(to: Data([0x01])))
                        }
                        it("checks send next iteration timeout error") {
                            client.listen()
                            self.waitForMainQueue()

                            verify(mockSocket, times(2)).readDatagram()
                            let timeoutError = UDPClientError.timeout
                            verify(mockDelegate).didStop(_: equal(to: client, equalWhen: { $0 === $1 }), by: equal(to: timeoutError, type: UDPClientError.self))
                        }
                    }
                }
            }
        }
        describe("#send(data)") {
            it("throws error when cant create address") {
                stub(mockSocket) { mock in
                    when(mock.createAddress(host: node.host, port: Int32(node.discoveryPort))).thenReturn(nil)
                }
                do {
                    try client.send(Data())
                } catch let error as UDPClientError {
                    XCTAssertEqual(error, UDPClientError.cantCreateAddress)
                } catch {
                    XCTFail("Wrong error!")
                }
                verify(mockSocket).createAddress(host: node.host, port: Int32(node.discoveryPort))
                verifyNoMoreInteractions(mockSocket)
            }
            it("send data to node") {
                let address = Socket.createAddress(for: "10.10.10.10", on: 1000)!
                let data = Data([0x01])
                stub(mockSocket) { mock in
                    when(mock.createAddress(host: node.host, port: Int32(node.discoveryPort))).thenReturn(address)
                    when(mock.write(from: equal(to: data), to: equal(to: address))).thenReturn(0)
                }
                try! client.send(data)
                verify(mockSocket).createAddress(host: node.host, port: Int32(node.discoveryPort))
                verify(mockSocket).write(from: equal(to: data), to: equal(to: address))
            }
        }
    }

}

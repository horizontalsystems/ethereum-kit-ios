import XCTest
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class DevP2PPeerTests: QuickSpec {

    override func spec() {
        let mockConnection = MockIDevP2PConnection()
        let mockCapabilityHelper = MockICapabilityHelper()
        let myCapabilities = [Capability(name: "les", version: 2)]
        let myNodeId = Data(repeating: 3, count: 18)
        let port = 30303
        let mockDelegate = MockIDevP2PPeerDelegate()

        var peer: DevP2PPeer!

        beforeEach {
            peer = DevP2PPeer(devP2PConnection: mockConnection, capabilityHelper: mockCapabilityHelper, myCapabilities: myCapabilities, myNodeId: myNodeId, port: port)
            peer.delegate = mockDelegate
        }

        afterEach {
            reset(mockConnection, mockCapabilityHelper, mockDelegate)
        }

        describe("#connect") {
            beforeEach {
                stub(mockConnection) { mock in
                    when(mock.connect()).thenDoNothing()
                }

                peer.connect()
            }

            it("connects devP2P connection") {
                verify(mockConnection).connect()
            }
        }

        describe("#disconnect") {
            let error = TestError()

            beforeEach {
                stub(mockConnection) { mock in
                    when(mock.disconnect(error: any())).thenDoNothing()
                }

                peer.disconnect(error: error)
            }

            it("disconnects devP2P connection") {
                verify(mockConnection).disconnect(error: equal(to: error, type: TestError.self))
            }
        }

        describe("#sendMessage") {
            let message = MockIOutMessage()

            beforeEach {
                stub(mockConnection) { mock in
                    when(mock.send(message: any())).thenDoNothing()
                }

                peer.send(message: message)
            }

            it("sends message to devP2P connection") {
                verify(mockConnection).send(message: equal(to: message, type: MockIOutMessage.self))
            }
        }

        describe("#didConnect") {
            let argumentCaptor = ArgumentCaptor<IOutMessage>()

            beforeEach {
                stub(mockConnection) { mock in
                    when(mock.send(message: any())).thenDoNothing()
                }

                peer.didConnect()
            }

            it("sends HelloMessage to devP2P connection") {
                verify(mockConnection).send(message: argumentCaptor.capture())

                let message = argumentCaptor.value as! HelloMessage

                expect(message.nodeId).to(equal(myNodeId))
                expect(message.port).to(equal(port))
                expect(message.capabilities).to(equal(myCapabilities))
            }
        }

        describe("#didDisconnect") {
            let error = TestError()

            beforeEach {
                stub(mockDelegate) { mock in
                    when(mock.didDisconnect(error: any())).thenDoNothing()
                }

                peer.didDisconnect(error: error)
            }

            it("notifies delegate") {
                verify(mockDelegate).didDisconnect(error: equal(to: error, type: TestError.self))
            }
        }

        describe("#didReceiveMessage") {
            beforeEach {
                stub(mockConnection) { mock in
                    when(mock.disconnect(error: any())).thenDoNothing()
                }
            }

            context("when message is HelloMessage") {
                let nodeCapabilities = [Capability(name: "eth", version: 3)]
                let helloMessage = HelloMessage(capabilities: nodeCapabilities)

                context("when has no shared capabilities") {
                    beforeEach {
                        stub(mockCapabilityHelper) { mock in
                            when(mock.sharedCapabilities(myCapabilities: equal(to: myCapabilities), nodeCapabilities: equal(to: nodeCapabilities))).thenReturn([])
                        }

                        peer.didReceive(message: helloMessage)
                    }

                    it("disconnects with noSharedCapabilties error") {
                        verify(mockConnection).disconnect(error: equal(to: DevP2PPeer.CapabilityError.noSharedCapabilities, type: DevP2PPeer.CapabilityError.self))
                    }
                }

                context("when has shared capabilities") {
                    let sharedCapabilities = [myCapabilities[0]]

                    beforeEach {
                        stub(mockCapabilityHelper) { mock in
                            when(mock.sharedCapabilities(myCapabilities: equal(to: myCapabilities), nodeCapabilities: equal(to: nodeCapabilities))).thenReturn(sharedCapabilities)
                        }
                        stub(mockConnection) { mock in
                            when(mock.register(sharedCapabilities: any())).thenDoNothing()
                        }
                        stub(mockDelegate) { mock in
                            when(mock.didConnect()).thenDoNothing()
                        }

                        peer.didReceive(message: helloMessage)
                    }

                    it("registers shared capabilities to connection") {
                        verify(mockConnection).register(sharedCapabilities: equal(to: sharedCapabilities))
                    }

                    it("notifies delegate that did connect") {
                        verify(mockDelegate).didConnect()
                    }
                }
            }

            context("when message is DisconnectMessage") {
                let disconnectMessage = DisconnectMessage()

                beforeEach {
                    peer.didReceive(message: disconnectMessage)
                }

                it("disconnects with disconnectMessageReceived error") {
                    verify(mockConnection).disconnect(error: equal(to: DevP2PPeer.DisconnectError.disconnectMessageReceived, type: DevP2PPeer.DisconnectError.self))
                }
            }

            context("when message is PingMessage") {
                let pingMessage = PingMessage()

                beforeEach {
                    stub(mockConnection) { mock in
                        when(mock.send(message: any())).thenDoNothing()
                    }

                    peer.didReceive(message: pingMessage)
                }

                it("sends PongMessage to devP2P connection") {
                    let argumentCaptor = ArgumentCaptor<IOutMessage>()
                    verify(mockConnection).send(message: argumentCaptor.capture())

                    expect(argumentCaptor.value! is PongMessage).to(beTrue())
                }
            }

            context("when message is PongMessage") {
                let pongMessage = PongMessage()

                beforeEach {
                    peer.didReceive(message: pongMessage)
                }

                it("does not notify delegate") {
                    verifyNoMoreInteractions(mockDelegate)
                }
            }

            context("when message is another message") {
                let message = MockIInMessage(data: Data())

                beforeEach {
                    stub(mockDelegate) { mock in
                        when(mock.didReceive(message: any())).thenDoNothing()
                    }

                    peer.didReceive(message: message)
                }

                it("notifies delegate that message is received") {
                    verify(mockDelegate).didReceive(message: equal(to: message, type: MockIInMessage.self))
                }
            }
        }
    }

}

import XCTest
import Quick
import Nimble
import Cuckoo
@testable import HSEthereumKit

class LESPeerTests: QuickSpec {
    override func spec() {
        let mockDevP2PPeer = MockIDevP2PPeer()
        let mockRequestHolder = MockLESPeerRequestHolder()
        let mockRandomHelper = MockIRandomHelper()
        let mockNetwork = MockINetwork()
        var lastBlockHeader = BlockHeader()
        let mockDelegate = MockILESPeerDelegate()

        var peer: LESPeer!

        let protocolVersion = LESPeer.capability.version
        let networkId = 1
        let genesisHash = Data(repeating: 1, count: 10)
        let blockTotalDifficulty: BInt = 12345
        let blockHash = Data(repeating: 3, count: 10)
        let blockHeight: BInt = 100

        beforeEach {
            stub(mockNetwork) { mock in
                when(mock.id.get).thenReturn(networkId)
                when(mock.genesisBlockHash.get).thenReturn(genesisHash)
            }

            lastBlockHeader = BlockHeader(hashHex: blockHash, totalDifficulty: blockTotalDifficulty, height: blockHeight)

            peer = LESPeer(devP2PPeer: mockDevP2PPeer, requestHolder: mockRequestHolder, randomHelper: mockRandomHelper, network: mockNetwork, lastBlockHeader: lastBlockHeader)
            peer.delegate = mockDelegate
        }

        afterEach {
            reset(mockDevP2PPeer, mockRequestHolder, mockRandomHelper, mockNetwork, mockDelegate)
        }

        describe("#connect") {
            it("connects devP2P peer") {
                stub(mockDevP2PPeer) { mock in
                    when(mock.connect()).thenDoNothing()
                }

                peer.connect()

                verify(mockDevP2PPeer).connect()
            }
        }

        describe("#disconnect") {
            it("disconnects devP2P peer") {
                let error = TestError()

                stub(mockDevP2PPeer) { mock in
                    when(mock.disconnect(error: any())).thenDoNothing()
                }

                peer.disconnect(error: error)

                verify(mockDevP2PPeer).disconnect(error: equal(to: error, type: TestError.self))
            }
        }

        describe("#requestBlockHeaders") {
            let requestId = 123
            let blockHeight: BInt = 123456
            let limit = 100

            beforeEach {
                stub(mockRandomHelper) { mock in
                    when(mock.randomInt.get).thenReturn(requestId)
                }
                stub(mockRequestHolder) { mock in
                    when(mock.set(blockHeaderRequest: any(), id: any())).thenDoNothing()
                }
                stub(mockDevP2PPeer) { mock in
                    when(mock.send(message: any())).thenDoNothing()
                }

                peer.requestBlockHeaders(blockHeight: blockHeight, limit: limit)
            }

            it("sets request to holder") {
                let argumentCaptor = ArgumentCaptor<BlockHeaderRequest>()
                verify(mockRequestHolder).set(blockHeaderRequest: argumentCaptor.capture(), id: requestId)
                let request = argumentCaptor.value!

                expect(request.blockHeight).to(equal(blockHeight))
            }

            it("sends message to devP2P peer") {
                let argumentCaptor = ArgumentCaptor<IOutMessage>()
                verify(mockDevP2PPeer).send(message: argumentCaptor.capture())
                let message = argumentCaptor.value as! GetBlockHeadersMessage

                expect(message.requestId).to(equal(requestId))
                expect(message.blockHeight).to(equal(blockHeight))
                expect(message.maxHeaders).to(equal(limit))
            }
        }

        describe("#requestAccountState") {
            let requestId = 123
            let address = Data(repeating: 123, count: 20)
            let blockHash = Data(repeating: 234, count: 20)
            let blockHeader = BlockHeader(hashHex: blockHash)

            beforeEach {
                stub(mockRandomHelper) { mock in
                    when(mock.randomInt.get).thenReturn(requestId)
                }
                stub(mockRequestHolder) { mock in
                    when(mock.set(accountStateRequest: any(), id: any())).thenDoNothing()
                }
                stub(mockDevP2PPeer) { mock in
                    when(mock.send(message: any())).thenDoNothing()
                }

                peer.requestAccountState(address: address, blockHeader: blockHeader)
            }

            it("sets request to holder") {
                let argumentCaptor = ArgumentCaptor<AccountStateRequest>()
                verify(mockRequestHolder).set(accountStateRequest: argumentCaptor.capture(), id: requestId)
                let request = argumentCaptor.value!

                expect(request.address).to(equal(address))
                expect(request.blockHeader).to(equal(blockHeader))
            }

            it("sends message to devP2P peer") {
                let argumentCaptor = ArgumentCaptor<IOutMessage>()
                verify(mockDevP2PPeer).send(message: argumentCaptor.capture())
                let message = argumentCaptor.value as! GetProofsMessage

                expect(message.requestId).to(equal(requestId))
                expect(message.proofRequests.count).to(equal(1))
                expect(message.proofRequests[0].blockHash).to(equal(blockHash))
                expect(message.proofRequests[0].key).to(equal(address))
            }
        }

        describe("#didConnect") {
            let argumentCaptor = ArgumentCaptor<IOutMessage>()

            beforeEach {
                stub(mockDevP2PPeer) { mock in
                    when(mock.send(message: any())).thenDoNothing()
                }

                peer.didConnect()
            }

            it("sends status message") {
                verify(mockDevP2PPeer).send(message: argumentCaptor.capture())

                let message = argumentCaptor.value as! StatusMessage

                expect(message.protocolVersion).to(equal(protocolVersion))
                expect(message.networkId).to(equal(networkId))
                expect(message.genesisHash).to(equal(genesisHash))
                expect(message.headTotalDifficulty).to(equal(blockTotalDifficulty))
                expect(message.headHash).to(equal(blockHash))
                expect(message.headHeight).to(equal(blockHeight))
            }
        }

        describe("#didDisconnect") {

        }

        describe("#didReceiveMessage") {
            beforeEach {
                stub(mockDevP2PPeer) { mock in
                    when(mock.disconnect(error: any())).thenDoNothing()
                }
            }

            context("when message is StatusMessage") {
                let statusMessage = StatusMessage()

                beforeEach {
                    statusMessage.protocolVersion = protocolVersion
                    statusMessage.networkId = networkId
                    statusMessage.genesisHash = genesisHash
                    statusMessage.headHeight = blockHeight
                }

                context("when valid") {
                    it("notifies delegate that connected") {
                        stub(mockDelegate) { mock in
                            when(mock.didConnect()).thenDoNothing()
                        }

                        peer.didReceive(message: statusMessage)

                        verify(mockDelegate).didConnect()
                    }
                }

                context("when invalid") {
                    it("does not notify delegate that connected") {
                        verify(mockDelegate, never()).didConnect()
                    }

                    context("protocolVersion") {
                        beforeEach {
                            statusMessage.protocolVersion = protocolVersion + 1
                            peer.didReceive(message: statusMessage)
                        }

                        it("disconnects with invalidProtocolVersion error") {
                            verify(mockDevP2PPeer).disconnect(error: equal(to: LESPeer.ValidationError.invalidProtocolVersion, type: LESPeer.ValidationError.self))
                        }
                    }

                    context("networkId") {
                        beforeEach {
                            statusMessage.networkId = 10
                            peer.didReceive(message: statusMessage)
                        }

                        it("disconnects with wrongNetwork error") {
                            verify(mockDevP2PPeer).disconnect(error: equal(to: LESPeer.ValidationError.wrongNetwork, type: LESPeer.ValidationError.self))
                        }
                    }

                    context("genesisBlockHash") {
                        beforeEach {
                            statusMessage.genesisHash = Data(repeating: 123, count: 10)
                            peer.didReceive(message: statusMessage)
                        }

                        it("disconnects with wrongNetwork error") {
                            verify(mockDevP2PPeer).disconnect(error: equal(to: LESPeer.ValidationError.wrongNetwork, type: LESPeer.ValidationError.self))
                        }
                    }

                    context("bestBlockHeight") {
                        beforeEach {
                            statusMessage.headHeight = blockHeight - 1
                            peer.didReceive(message: statusMessage)
                        }

                        it("disconnects with expiredBestBlockHeight error") {
                            verify(mockDevP2PPeer).disconnect(error: equal(to: LESPeer.ValidationError.expiredBestBlockHeight, type: LESPeer.ValidationError.self))
                        }
                    }
                }
            }

            context("when message is BlockHeadersMessage") {
                let requestId = 123
                let blockHeaders = [BlockHeader()]
                let message = BlockHeadersMessage(requestId: requestId, headers: blockHeaders)

                context("when request exists in holder") {
                    let blockHeight: BInt = 123456

                    beforeEach {
                        let request = BlockHeaderRequest(blockHeight: blockHeight)

                        stub(mockRequestHolder) { mock in
                            when(mock.removeBlockHeaderRequest(id: requestId)).thenReturn(request)
                        }
                        stub(mockDelegate) { mock in
                            when(mock.didReceive(blockHeaders: any(), blockHeight: any())).thenDoNothing()
                        }

                        peer.didReceive(message: message)
                    }

                    it("notifies delegate") {
                        verify(mockDelegate).didReceive(blockHeaders: equal(to: blockHeaders), blockHeight: equal(to: blockHeight))
                    }
                }

                context("when request does not exist in holder") {
                    beforeEach {
                        stub(mockRequestHolder) { mock in
                            when(mock.removeBlockHeaderRequest(id: requestId)).thenReturn(nil)
                        }

                        peer.didReceive(message: message)
                    }

                    it("disconnects with unexpectedMessage error") {
                        verify(mockDevP2PPeer).disconnect(error: equal(to: LESPeer.ConsistencyError.unexpectedMessage, type: LESPeer.ConsistencyError.self))
                    }

                    it("does not notify delegate") {
                        verify(mockDelegate, never()).didReceive(blockHeaders: any(), blockHeight: any())
                    }
                }
            }

            context("when message is ProofsMessage") {
                let requestId = 123
                let message = ProofsMessage(requestId: requestId)

                context("when request exists in holder") {
                    let address = Data(repeating: 1, count: 10)
                    let blockHeader = BlockHeader()
                    let accountState = AccountState()

                    beforeEach {
                        let mockRequest = MockAccountStateRequest(address: address, blockHeader: blockHeader)

                        stub(mockRequest) { mock in
                            when(mock.accountState(proofsMessage: equal(to: message))).thenReturn(accountState)
                        }
                        stub(mockRequestHolder) { mock in
                            when(mock.removeAccountStateRequest(id: requestId)).thenReturn(mockRequest)
                        }
                        stub(mockDelegate) { mock in
                            when(mock.didReceive(accountState: any(), address: any(), blockHeader: any())).thenDoNothing()
                        }

                        peer.didReceive(message: message)
                    }

                    it("notifies delegate") {
                        verify(mockDelegate).didReceive(accountState: equal(to: accountState), address: equal(to: address), blockHeader: equal(to: blockHeader))
                    }
                }

                context("when request does not exist in holder") {
                    beforeEach {
                        stub(mockRequestHolder) { mock in
                            when(mock.removeAccountStateRequest(id: requestId)).thenReturn(nil)
                        }

                        peer.didReceive(message: message)
                    }

                    it("disconnects with unexpectedMessage error") {
                        verify(mockDevP2PPeer).disconnect(error: equal(to: LESPeer.ConsistencyError.unexpectedMessage, type: LESPeer.ConsistencyError.self))
                    }

                    it("does not notify delegate") {
                        verify(mockDelegate, never()).didReceive(accountState: any(), address: any(), blockHeader: any())
                    }
                }
            }

            context("when message is AnnounceMessage") {
                let blockHash = Data(repeating: 111, count: 4)
                let blockHeight: BInt = 1234
                let message = AnnounceMessage(lastBlockHash: blockHash, lastBlockHeight: blockHeight)

                beforeEach {
                    stub(mockDelegate) { mock in
                        when(mock.didAnnounce(blockHash: any(), blockHeight: any())).thenDoNothing()
                    }

                    peer.didReceive(message: message)
                }

                it("notifies delegate") {
                    verify(mockDelegate).didAnnounce(blockHash: equal(to: blockHash), blockHeight: equal(to: blockHeight))
                }
            }
        }
    }

}

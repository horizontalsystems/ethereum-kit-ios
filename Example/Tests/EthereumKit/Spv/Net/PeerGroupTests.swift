import XCTest
import BigInt
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class PeerGroupTests: QuickSpec {

    override func spec() {
        let mockStorage = MockISpvStorage()
        let mockPeerProvider = MockIPeerProvider()
        let mockValidator = MockBlockValidator()
        let mockBlockHelper = MockIBlockHelper()
        let mockState = MockPeerGroupState()
        let mockDelegate = MockIPeerGroupDelegate()
        let address = Data(repeating: 1, count: 20)
        let limit = 2

        let peerGroup = PeerGroup(storage: mockStorage, peerProvider: mockPeerProvider, validator: mockValidator, blockHelper: mockBlockHelper, state: mockState, address: address, headersLimit: limit)
        peerGroup.delegate = mockDelegate

        beforeEach {
        }

        afterEach {
            reset(mockStorage, mockPeerProvider, mockValidator, mockBlockHelper, mockState, mockDelegate)
        }

        describe("#syncState") {
            let syncState: EthereumKit.SyncState = .syncing

            beforeEach {
                stub(mockState) { mock in
                    when(mock.syncState.get).thenReturn(syncState)
                }
            }

            it("returns sync state from state") {
                expect(peerGroup.syncState).to(equal(syncState))
            }
        }

        describe("#start") {
            let mockPeer = MockIPeer()

            beforeEach {
                stub(mockPeerProvider) { mock in
                    when(mock.peer()).thenReturn(mockPeer)
                }
                stub(mockState) { mock in
                    when(mock.syncState.set(any())).thenDoNothing()
                    when(mock.syncPeer.set(any())).thenDoNothing()
                }
                stub(mockDelegate) { mock in
                    when(mock.onUpdate(syncState: any())).thenDoNothing()
                }
                stub(mockPeer) { mock in
                    when(mock.connect()).thenDoNothing()
                    when(mock.delegate.set(any())).thenDoNothing()
                }

                peerGroup.start()
            }

            afterEach {
                reset(mockPeer)
            }

            it("sets `syncing` sync state to state") {
                verify(mockState).syncState.set(equal(to: EthereumKit.SyncState.syncing))
            }

            it("notifies delegate that sync state changed to `syncing`") {
                verify(mockDelegate).onUpdate(syncState: equal(to: EthereumKit.SyncState.syncing))
            }

            it("sets sync peer delegate to self") {
                verify(mockPeer).delegate.set(equal(to: peerGroup, type: PeerGroup.self))
            }

            it("sets sync peer to state") {
                verify(mockState).syncPeer.set(equal(to: mockPeer, type: MockIPeer.self))
            }

            it("connects sync peer") {
                verify(mockPeer).connect()
            }
        }

        describe("#sendTransaction") {
            let mockPeer = MockIPeer()
            let rawTransaction = RawTransaction()
            let signature: (v: BigUInt, r: BigUInt, s: BigUInt) = (0, 0, 0)

            beforeEach {
                stub(mockState) { mock in
                    when(mock.syncPeer.get).thenReturn(mockPeer)
                }
                stub(mockPeer) { mock in
                    when(mock.send(rawTransaction: any(), signature: any())).thenDoNothing()
                }

                peerGroup.send(rawTransaction: rawTransaction, signature: signature)
            }

            afterEach {
                reset(mockPeer)
            }

            it("sends transaction to sync peer") {
                verify(mockPeer).send(rawTransaction: sameInstance(as: rawTransaction), signature: any())
            }
        }

        describe("#didConnect") {
            let mockPeer = MockIPeer()
            let lastBlockHeader = BlockHeader()

            beforeEach {
                stub(mockState) { mock in
                    when(mock.syncPeer.get).thenReturn(mockPeer)
                }
                stub(mockBlockHelper) { mock in
                    when(mock.lastBlockHeader.get).thenReturn(lastBlockHeader)
                }
                stub(mockPeer) { mock in
                    when(mock.requestBlockHeaders(blockHeader: any(), limit: any(), reverse: any())).thenDoNothing()
                }

                peerGroup.didConnect()
            }

            afterEach {
                reset(mockPeer)
            }

            it("requests block headers from peer using last block height") {
                verify(mockPeer).requestBlockHeaders(blockHeader: equal(to: lastBlockHeader), limit: equal(to: limit), reverse: false)
            }
        }

        describe("#didDisconnect") {
            beforeEach {
                stub(mockState) { mock in
                    when(mock.syncPeer.set(any())).thenDoNothing()
                }

                peerGroup.didDisconnect(error: nil)
            }

            it("sets sync peer to nil in state") {
//                verify(mockState).syncPeer.set(nil)
            }
        }

        describe("#didReceiveBlockHeaders") {
            let lastBlockHeader = BlockHeader()
            let firstHeader = BlockHeader()
            let secondHeader = BlockHeader()

            beforeEach {
                stub(mockValidator) { mock in
                    when(mock.validate(blockHeaders: any(), from: any())).thenDoNothing()
                }
            }

            context("when block headers are valid") {
                let mockPeer = MockIPeer()

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.syncPeer.get).thenReturn(mockPeer)
                    }
                    stub(mockStorage) { mock in
                        when(mock.save(blockHeaders: any())).thenDoNothing()
                    }
                    stub(mockPeer) { mock in
                        when(mock.requestBlockHeaders(blockHeader: any(), limit: any(), reverse: any())).thenDoNothing()
                    }
                }

                afterEach {
                    reset(mockPeer)
                }

                it("saves all block headers except first one to storage") {
                    peerGroup.didReceive(blockHeaders: [firstHeader, secondHeader], blockHeader: lastBlockHeader, reverse: false)
                    verify(mockStorage).save(blockHeaders: equal(to: [firstHeader, secondHeader]))
                }

                context("when blocks count is the same as limit") {
                    beforeEach {
                        peerGroup.didReceive(blockHeaders: [firstHeader, secondHeader], blockHeader: lastBlockHeader, reverse: false)
                    }

                    it("requests more block headers starting from last received block header") {
                        verify(mockPeer).requestBlockHeaders(blockHeader: equal(to: secondHeader), limit: equal(to: limit), reverse: false)
                    }
                }

                context("when blocks count is less then limit") {
                    beforeEach {
                        stub(mockPeer) { mock in
                            when(mock.requestAccountState(address: any(), blockHeader: any())).thenDoNothing()
                        }

                        peerGroup.didReceive(blockHeaders: [firstHeader], blockHeader: lastBlockHeader, reverse: false)
                    }

                    it("does not request any more block headers") {
                        verify(mockPeer, never()).requestBlockHeaders(blockHeader: any(), limit: any(), reverse: any())
                    }

                    it("requests account state for last received block header") {
                        verify(mockPeer).requestAccountState(address: equal(to: address), blockHeader: equal(to: firstHeader))
                    }
                }
            }

            context("when validator throws ForkDetected error") {
                let mockPeer = MockIPeer()

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.syncPeer.get).thenReturn(mockPeer)
                    }
                    stub(mockValidator) { mock in
                        when(mock.validate(blockHeaders: equal(to: [firstHeader, secondHeader]), from: equal(to: lastBlockHeader))).thenThrow(BlockValidator.ValidationError.forkDetected)
                    }
                    stub(mockPeer) { mock in
                        when(mock.requestBlockHeaders(blockHeader: any(), limit: any(), reverse: any())).thenDoNothing()
                    }

                    peerGroup.didReceive(blockHeaders: [firstHeader, secondHeader], blockHeader: lastBlockHeader, reverse: false)
                }

                afterEach {
                    reset(mockPeer)
                }

                it("requests reversed block headers for block header") {
                    verify(mockPeer).requestBlockHeaders(blockHeader: equal(to: lastBlockHeader), limit: equal(to: limit), reverse: true)
                }
            }

            context("when validator throws validation error") {
                let error = TestError()
                let mockPeer = MockIPeer()

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.syncPeer.get).thenReturn(mockPeer)
                    }
                    stub(mockValidator) { mock in
                        when(mock.validate(blockHeaders: equal(to: [firstHeader, secondHeader]), from: equal(to: lastBlockHeader))).thenThrow(error)
                    }
                    stub(mockPeer) { mock in
                        when(mock.disconnect(error: any())).thenDoNothing()
                    }

                    peerGroup.didReceive(blockHeaders: [firstHeader, secondHeader], blockHeader: lastBlockHeader, reverse: false)
                }

                afterEach {
                    reset(mockPeer)
                }

                it("disconnects peer") {
                    verify(mockPeer).disconnect(error: equal(to: error, type: TestError.self))
                }
            }
        }

        describe("#didReceiveReversedBlockHeaders") {
            let mockPeer = MockIPeer()

            let forkHeaderHash = Data(repeating: 1, count: 10)
            let forkHeaderHeight = 99

            let firstReceivedHeader = BlockHeader(hashHex: Data(repeating: 2, count: 10), height: 100)

            let firstStoredHeader = BlockHeader(hashHex: Data(repeating: 3, count: 10), height: 100)
            let secondStoredHeader = BlockHeader(hashHex: forkHeaderHash, height: forkHeaderHeight)

            beforeEach {
                stub(mockState) { mock in
                    when(mock.syncPeer.get).thenReturn(mockPeer)
                }
                stub(mockStorage) { mock in
                    when(mock.reversedLastBlockHeaders(from: equal(to: firstStoredHeader.height), limit: equal(to: 2))).thenReturn([firstStoredHeader, secondStoredHeader])
                }
            }

            afterEach {
                reset(mockPeer)
            }

            context("when fork block header exists") {
                let validReceivedHeader = BlockHeader(hashHex: forkHeaderHash, height: forkHeaderHeight)

                beforeEach {
                    stub(mockPeer) { mock in
                        when(mock.requestBlockHeaders(blockHeader: any(), limit: any(), reverse: any())).thenDoNothing()
                    }

                    peerGroup.didReceive(blockHeaders: [firstReceivedHeader, validReceivedHeader], blockHeader: firstStoredHeader, reverse: true)
                }

                it("requests blocks headers from fork block header") {
                    verify(mockPeer).requestBlockHeaders(blockHeader: equal(to: secondStoredHeader), limit: equal(to: limit), reverse: false)
                }
            }

            context("when fork block header does not exist") {
                let invalidReceivedHeader = BlockHeader(hashHex: Data(repeating: 5, count: 10), height: forkHeaderHeight)

                beforeEach {
                    stub(mockPeer) { mock in
                        when(mock.disconnect(error: any())).thenDoNothing()
                    }

                    peerGroup.didReceive(blockHeaders: [firstReceivedHeader, invalidReceivedHeader], blockHeader: firstStoredHeader, reverse: true)
                }

                it("disconnects peer with invalidPeer error") {
                    verify(mockPeer).disconnect(error: equal(to: PeerGroup.PeerError.invalidForkedPeer, type: PeerGroup.PeerError.self))
                }
            }
        }

        describe("#didReceiveAccountState") {
            let accountState = AccountStateSpv()

            beforeEach {
                stub(mockDelegate) { mock in
                    when(mock.onUpdate(accountState: any())).thenDoNothing()
                    when(mock.onUpdate(syncState: any())).thenDoNothing()
                }
                stub(mockState) { mock in
                    when(mock.syncState.set(any())).thenDoNothing()
                }

                peerGroup.didReceive(accountState: accountState, address: Data(), blockHeader: BlockHeader())
            }

            it("notifies delegate about account state update") {
                verify(mockDelegate).onUpdate(accountState: equal(to: accountState))
            }

            it("sets `synced` sync state to state") {
                verify(mockState).syncState.set(equal(to: EthereumKit.SyncState.synced))
            }

            it("notifies delegate that sync state changed to `synced`") {
                verify(mockDelegate).onUpdate(syncState: equal(to: EthereumKit.SyncState.synced))
            }
        }

        describe("#didAnnounce") {
            let mockPeer = MockIPeer()

            beforeEach {
                stub(mockState) { mock in
                    when(mock.syncPeer.get).thenReturn(mockPeer)
                }
            }

            afterEach {
                reset(mockPeer)
            }

            context("when sync state is not `synced`") {
                beforeEach {
                    stub(mockState) { mock in
                        when(mock.syncState.get).thenReturn(EthereumKit.SyncState.syncing)
                    }

                    peerGroup.didAnnounce(blockHash: Data(), blockHeight: 0)
                }

                it("should not request any block headers") {
                    verify(mockPeer, never()).requestBlockHeaders(blockHeader: any(), limit: any(), reverse: any())
                }
            }

            context("when sync state is `synced`") {
                let lastBlockHeader = BlockHeader()

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.syncState.get).thenReturn(EthereumKit.SyncState.synced)
                    }
                    stub(mockBlockHelper) { mock in
                        when(mock.lastBlockHeader.get).thenReturn(lastBlockHeader)
                    }
                    stub(mockPeer) { mock in
                        when(mock.requestBlockHeaders(blockHeader: any(), limit: any(), reverse: any())).thenDoNothing()
                    }

                    peerGroup.didAnnounce(blockHash: Data(), blockHeight: 0)
                }

                it("requests block headers from peer using last block height") {
                    verify(mockPeer).requestBlockHeaders(blockHeader: equal(to: lastBlockHeader), limit: equal(to: limit), reverse: false)
                }
            }

        }
    }

}

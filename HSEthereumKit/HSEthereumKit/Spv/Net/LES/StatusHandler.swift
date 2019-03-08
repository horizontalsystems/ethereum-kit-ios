class StatusHandler {
    let network: INetwork
    let blockHeader: BlockHeader

    init(network: INetwork, blockHeader: BlockHeader) {
        self.network = network
        self.blockHeader = blockHeader
    }

}

extension StatusHandler: IStatusHandler {

    func validate(message: StatusMessage) throws {
        guard message.networkId == network.id && message.genesisHash == network.genesisBlockHash else {
            throw LESPeer.ValidationError.wrongNetwork
        }

        guard message.headHeight > 0 else {
            throw LESPeer.ValidationError.peerBestBlockIsLessThanOne
        }

        guard message.headHeight >= blockHeader.height else {
            throw LESPeer.ValidationError.peerHasExpiredBlockChain(localHeight: blockHeader.height, peerHeight: message.headHeight)
        }
    }

}

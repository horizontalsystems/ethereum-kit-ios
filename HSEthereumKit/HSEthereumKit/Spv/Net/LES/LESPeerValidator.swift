class LESPeerValidator {
}

extension LESPeerValidator: ILESPeerValidator {

    func validate(message: StatusMessage, network: INetwork, blockHeader: BlockHeader) throws {
        guard message.networkId == network.id && message.genesisHash == network.genesisBlockHash else {
            throw LESPeer.ValidationError.wrongNetwork
        }

        guard message.headHeight >= blockHeader.height else {
            throw LESPeer.ValidationError.peerHasExpiredBlockChain(localHeight: blockHeader.height, peerHeight: message.headHeight)
        }
    }

}

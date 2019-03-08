class MessageFactory: IMessageFactory {

    func helloMessage(key: ECKey, capabilities: [Capability]) -> HelloMessage {
        return HelloMessage(peerId: key.publicKeyPoint.x + key.publicKeyPoint.y, port: 30303, capabilities: capabilities)
    }

    func pongMessage() -> PongMessage {
        return PongMessage()
    }

    func getBlockHeadersMessage(blockHash: Data) -> GetBlockHeadersMessage {
        return GetBlockHeadersMessage(requestId: Int.random(in: 0..<Int.max), blockHash: blockHash)
    }

    func getProofsMessage(address: Data, blockHash: Data) -> GetProofsMessage {
        return GetProofsMessage(requestId: Int.random(in: 0..<Int.max), blockHash: blockHash, key: address, key2: Data())
    }

    func statusMessage(network: INetwork, blockHeader: BlockHeader) -> StatusMessage {
        return StatusMessage(
                protocolVersion: 2,
                networkId: network.id,
                genesisHash: network.genesisBlockHash,
                headTotalDifficulty: blockHeader.totalDifficulty,
                headHash: blockHeader.hashHex,
                headHeight: blockHeader.height
        )
    }

}

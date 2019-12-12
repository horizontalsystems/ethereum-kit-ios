import BigInt

class HandshakeTask: ITask {
    let peerId: String

    let networkId: Int
    let genesisHash: Data
    let headTotalDifficulty: BigUInt
    let headHash: Data
    let headHeight: Int

    init(peerId: String, network: INetwork, blockHeader: BlockHeader) {
        self.peerId = peerId

        networkId = network.chainId
        genesisHash = network.genesisBlockHash
        headTotalDifficulty = blockHeader.totalDifficulty
        headHash = blockHeader.hashHex
        headHeight = blockHeader.height
    }
}

class Kovan: INetwork {
    let chainId = 42
    let genesisBlockHash = Data(hex: "")!

    let checkpointBlock = BlockHeader(
            hashHex: Data(hex: "")!,
            totalDifficulty: 0,
            parentHash: Data(),
            unclesHash: Data(),
            coinbase: Data(),
            stateRoot: Data(),
            transactionsRoot: Data(),
            receiptsRoot: Data(),
            logsBloom: Data(),
            difficulty: 0,
            height: 0,
            gasLimit: 0,
            gasUsed: 0,
            timestamp: 0,
            extraData: Data(),
            mixHash: Data(),
            nonce: Data()
    )


// TestnetBootnodes are the enode URLs of the P2P bootstrap nodes running on the
// Kovan test network.
    let bootnodes: [String] = []

}

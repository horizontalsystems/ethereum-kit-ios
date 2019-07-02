class Ropsten: INetwork {
    let chainId = 3
    let genesisBlockHash = Data(hex: "0x41941023680923e0fe4d74a34bdac8141f2540e3ae90623718e47d66d1ca4a2d")!

    let checkpointBlock = BlockHeader(
            hashHex: Data(hex: "0xb6cf198de61afe5cf53a588cf9b61c5f83900252304164755df3c1cb62847af8")!,
            totalDifficulty: "19605563365967884",
            parentHash: Data(),
            unclesHash: Data(),
            coinbase: Data(),
            stateRoot: Data(),
            transactionsRoot: Data(),
            receiptsRoot: Data(),
            logsBloom: Data(),
            difficulty: 0,
            height: 5600855,
            gasLimit: 0,
            gasUsed: 0,
            timestamp: 0,
            extraData: Data(),
            mixHash: Data(),
            nonce: Data()
    )

// TestnetBootnodes are the enode URLs of the P2P bootstrap nodes running on the
// Ropsten test network.
    let bootnodes = [
        "enode://30b7ab30a01c124a6cceca36863ece12c4f5fa68e3ba9b0b51407ccc002eeed3b3102d20a88f1c1d3c3154e2449317b8ef95090e77b312d5cc39354f86d5d606@52.176.7.10:30303?discport=30303",    // US-Azure geth
        "enode://865a63255b3bb68023b6bffd5095118fcc13e79dcf014fe4e47e065c350c7cc72af2e53eff895f11ba1bbb6a2b33271c1116ee870f266618eadfc2e78aa7349c@52.176.100.77:30303?discport=30303",  // US-Azure parity
        "enode://6332792c4a00e3e4ee0926ed89e0d27ef985424d97b6a45bf0f23e51f0dcb5e66b875777506458aea7af6f9e4ffb69f43f3778ee73c81ed9d34c51c4b16b0b0f@52.232.243.152:30303?discport=30303", // Parity
        "enode://94c15d1b9e2fe7ce56e458b9a3b672ef11894ddedd0c6f247e0f1d3487f52b66208fb4aeb8179fce6e3a749ea93ed147c37976d67af557508d199d9594c35f09@192.81.208.223:30303?discport=30303", // @gpip
    ]

}

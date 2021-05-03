class BscMainNet: INetwork {
    let chainId = 56

    // todo: the following data is invalid and was copied from Ropsten

    let genesisBlockHash = Data()

    let checkpointBlock = BlockHeader(
            hashHex: Data(),
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

    let bootnodes = [String]()
    let blockTime: TimeInterval = 5.0
}

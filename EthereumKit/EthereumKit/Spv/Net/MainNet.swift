class MainNet: INetwork {
    // todo: the following data is invalid and was copied from Ropsten

    let chainId = 3
    let genesisBlockHash = Data(hex: "41941023680923e0fe4d74a34bdac8141f2540e3ae90623718e47d66d1ca4a2d")!

    let checkpointBlock = BlockHeader(
            hashHex: Data(hex: "9cb88ed0cc268d188755b0cf5ff8cca9b01eb53a0b3ebcdb35fb319882a041ee")!,
            totalDifficulty: 0,
            parentHash: Data(),
            unclesHash: Data(),
            coinbase: Data(),
            stateRoot: Data(),
            transactionsRoot: Data(),
            receiptsRoot: Data(),
            logsBloom: Data(),
            difficulty: 0,
            height: 5279800,
            gasLimit: 0,
            gasUsed: 0,
            timestamp: 0,
            extraData: Data(),
            mixHash: Data(),
            nonce: Data()
    )

}

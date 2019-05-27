class MainNet: INetwork {
    let chainId = 1

    // todo: the following data is invalid and was copied from Ropsten

    let genesisBlockHash = Data(hex: "0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3")!

    let checkpointBlock = BlockHeader(
            hashHex: Data(hex: "0x315b69e5a5f80c495a53e0014131abb4ddf8ca1434621b2faa7304c8b9b5b7ee")!,
            totalDifficulty: 0,
            parentHash: Data(),
            unclesHash: Data(),
            coinbase: Data(),
            stateRoot: Data(),
            transactionsRoot: Data(),
            receiptsRoot: Data(),
            logsBloom: Data(),
            difficulty: 0,
            height: 7770000,
            gasLimit: 0,
            gasUsed: 0,
            timestamp: 0,
            extraData: Data(),
            mixHash: Data(),
            nonce: Data()
    )

}

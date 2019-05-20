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

}

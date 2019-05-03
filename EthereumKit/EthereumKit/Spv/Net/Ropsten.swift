class Ropsten: INetwork {
    let chainId = 3
    let genesisBlockHash = Data(hex: "0x41941023680923e0fe4d74a34bdac8141f2540e3ae90623718e47d66d1ca4a2d")!

    let checkpointBlock = BlockHeader(
            hashHex: Data(hex: "0xaea8c82a8a24dad1c80681b68f23d72476827438bbcfaecc417da6cf95ccb23a")!,
            totalDifficulty: "19440576962369624",
            parentHash: Data(),
            unclesHash: Data(),
            coinbase: Data(),
            stateRoot: Data(),
            transactionsRoot: Data(),
            receiptsRoot: Data(),
            logsBloom: Data(),
            difficulty: 0,
            height: 5511420,
            gasLimit: 0,
            gasUsed: 0,
            timestamp: 0,
            extraData: Data(),
            mixHash: Data(),
            nonce: Data()
    )

}

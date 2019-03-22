class BlockHelper {
    private let storage: ISpvStorage
    private let network: INetwork

    init(storage: ISpvStorage, network: INetwork) {
        self.storage = storage
        self.network = network
    }

}

extension BlockHelper: IBlockHelper {

    var lastBlockHeader: BlockHeader {
        return storage.lastBlockHeader ?? network.checkpointBlock
    }

}

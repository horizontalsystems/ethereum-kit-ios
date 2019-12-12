class BlockHeadersTask: ITask {
    let blockHeader: BlockHeader
    let limit: Int
    let reverse: Bool

    init(blockHeader: BlockHeader, limit: Int, reverse: Bool) {
        self.blockHeader = blockHeader
        self.limit = limit
        self.reverse = reverse
    }

}

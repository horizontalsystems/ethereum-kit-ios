class BlockHeaderRequest {
    let blockHeader: BlockHeader
    let reverse: Bool

    init(blockHeader: BlockHeader, reverse: Bool) {
        self.blockHeader = blockHeader
        self.reverse = reverse
    }

}

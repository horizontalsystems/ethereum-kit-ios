class AccountStateTask: ITask {
    let address: Data
    let blockHeader: BlockHeader

    init(address: Data, blockHeader: BlockHeader) {
        self.address = address
        self.blockHeader = blockHeader
    }

}

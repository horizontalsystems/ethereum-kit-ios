class AccountStateTask: ITask {
    let address: Address
    let blockHeader: BlockHeader

    init(address: Address, blockHeader: BlockHeader) {
        self.address = address
        self.blockHeader = blockHeader
    }

}

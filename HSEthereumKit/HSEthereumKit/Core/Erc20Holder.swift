class Erc20Holder {
    let contractAddress: Data
    let delegate: IEthereumKitDelegate

    var balance: BInt?

    init(contractAddress: Data, delegate: IEthereumKitDelegate) {
        self.contractAddress = contractAddress
        self.delegate = delegate
    }

}

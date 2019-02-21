class Erc20Holder {
    let contractAddress: String
    let delegate: IEthereumKitDelegate

    var balance: String?

    init(contractAddress: String, delegate: IEthereumKitDelegate) {
        self.contractAddress = contractAddress
        self.delegate = delegate
    }

}

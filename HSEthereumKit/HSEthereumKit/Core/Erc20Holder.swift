import Foundation

class Erc20Holder {
    let contractAddress: String
    let decimal: Int
    let delegate: IEthereumKitDelegate

    var balance: Decimal?
    var syncState: EthereumKit.SyncState?

    init(contractAddress: String, decimal: Int, delegate: IEthereumKitDelegate) {
        self.contractAddress = contractAddress
        self.decimal = decimal
        self.delegate = delegate
    }

}

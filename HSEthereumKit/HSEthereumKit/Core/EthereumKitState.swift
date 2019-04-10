class EthereumKitState {

    var balance: BInt?
    var lastBlockHeight: Int?

    func clear() {
        balance = nil
        lastBlockHeight = nil
    }

}

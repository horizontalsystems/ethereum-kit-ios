import BigInt

class EthereumKitState {
    var balance: BigUInt?
    var lastBlockHeight: Int?

    func clear() {
        balance = nil
        lastBlockHeight = nil
    }

}

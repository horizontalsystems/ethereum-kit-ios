class EthereumKitState {

    var balance: BInt?
    var lastBlockHeight: Int?

    private var erc20Holders: [Data: Erc20Holder] = [:]

    var erc20Delegates: [IEthereumKitDelegate] {
        return erc20Holders.values.map { $0.delegate }
    }

    func has(contractAddress: Data) -> Bool {
        return erc20Holders[contractAddress] != nil
    }

    func add(contractAddress: Data, delegate: IEthereumKitDelegate) {
        erc20Holders[contractAddress] = Erc20Holder(contractAddress: contractAddress, delegate: delegate)
    }

    func remove(contractAddress: Data) {
        erc20Holders.removeValue(forKey: contractAddress)
    }

    func balance(contractAddress: Data) -> BInt? {
        return erc20Holders[contractAddress]?.balance
    }

    func set(balance: BInt?, contractAddress: Data) {
        erc20Holders[contractAddress]?.balance = balance
    }

    func delegate(contractAddress: Data) -> IEthereumKitDelegate? {
        return erc20Holders[contractAddress]?.delegate
    }

    func clear() {
        balance = nil
        lastBlockHeight = nil
        erc20Holders = [:]
    }

}

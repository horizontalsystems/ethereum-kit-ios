class EthereumKitState {

    var balance: String?
    var lastBlockHeight: Int?

    private var erc20Holders: [String: Erc20Holder] = [:]

    var erc20Delegates: [IEthereumKitDelegate] {
        return erc20Holders.values.map { $0.delegate }
    }

    func has(contractAddress: String) -> Bool {
        return erc20Holders[contractAddress] != nil
    }

    func add(contractAddress: String, delegate: IEthereumKitDelegate) {
        erc20Holders[contractAddress] = Erc20Holder(contractAddress: contractAddress, delegate: delegate)
    }

    func remove(contractAddress: String) {
        erc20Holders.removeValue(forKey: contractAddress)
    }

    func balance(contractAddress: String) -> String? {
        return erc20Holders[contractAddress]?.balance
    }

    func set(balance: String?, contractAddress: String) {
        erc20Holders[contractAddress]?.balance = balance
    }

    func delegate(contractAddress: String) -> IEthereumKitDelegate? {
        return erc20Holders[contractAddress]?.delegate
    }

    func clear() {
        balance = nil
        lastBlockHeight = nil
        erc20Holders = [:]
    }

}

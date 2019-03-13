class AccountState {
    let address: Data
    let nonce: Int
    let balance: Balance
    let storageHash: Data // Storage Trie root hash
    let codeHash: Data

    init(address: Data, nonce: Int, balance: Balance, storageHash: Data, codeHash: Data) {
        self.address = address
        self.nonce = nonce
        self.balance = balance
        self.storageHash = storageHash
        self.codeHash = codeHash
    }

    func toString() -> String {
        return "(\n" +
                "  nonce: \(nonce)\n" + 
                "  balance: \(balance.wei.asString(withBase: 10))\n" + 
                "  storageHash: \(storageHash.toHexString())\n" + 
                "  codeHash: \(codeHash.toHexString())\n" +
                ")"
    }

}

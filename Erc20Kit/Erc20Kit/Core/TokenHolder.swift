import RxSwift

class TokenHolder {
    private var tokensMap = [Data: Token]()

    private func token(contractAddress: Data) throws -> Token {
        guard let token = tokensMap[contractAddress] else {
            throw Erc20Kit.TokenError.notRegistered
        }

        return token
    }
}

extension TokenHolder: ITokenHolder {

    var contractAddresses: [Data] {
        return Array(tokensMap.keys)
    }

    func syncState(contractAddress: Data) throws -> Erc20Kit.SyncState {
        return try token(contractAddress: contractAddress).syncState
    }

    func balance(contractAddress: Data) throws -> TokenBalance {
        return try token(contractAddress: contractAddress).balance
    }

    func syncStateSubject(contractAddress: Data) throws -> PublishSubject<Erc20Kit.SyncState> {
        return try token(contractAddress: contractAddress).syncStateSubject
    }

    func balanceSubject(contractAddress: Data) throws -> PublishSubject<String> {
        return try token(contractAddress: contractAddress).balanceSubject
    }

    func transactionsSubject(contractAddress: Data) throws -> PublishSubject<[TransactionInfo]> {
        return try token(contractAddress: contractAddress).transactionsSubject
    }

    func register(contractAddress: Data, balance: TokenBalance) {
        let token = Token(contractAddress: contractAddress, balance: balance)

        tokensMap[contractAddress] = token
    }

    func unregister(contractAddress: Data) {
        tokensMap.removeValue(forKey: contractAddress)
    }

    func set(syncState: Erc20Kit.SyncState, contractAddress: Data) throws {
        try token(contractAddress: contractAddress).syncState = syncState
    }

    func set(balance: TokenBalance, contractAddress: Data) throws {
        try token(contractAddress: contractAddress).balance = balance
    }

    func clear() {
        tokensMap = [:]
    }

}

extension TokenHolder {

    class Token {
        let contractAddress: Data

        var balance: TokenBalance
        var syncState: Erc20Kit.SyncState = .notSynced

        let syncStateSubject = PublishSubject<Erc20Kit.SyncState>()
        let balanceSubject = PublishSubject<String>()
        let transactionsSubject = PublishSubject<[TransactionInfo]>()

        init(contractAddress: Data, balance: TokenBalance) {
            self.contractAddress = contractAddress
            self.balance = balance
        }

    }

}

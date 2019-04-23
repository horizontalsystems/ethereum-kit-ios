import RxSwift
import EthereumKit

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

    func balancePosition(contractAddress: Data) throws -> Int {
        return try token(contractAddress: contractAddress).balancePosition
    }

    func syncStateSignal(contractAddress: Data) throws -> Signal {
        return try token(contractAddress: contractAddress).syncStateSignal
    }

    func balanceSignal(contractAddress: Data) throws -> Signal {
        return try token(contractAddress: contractAddress).balanceSignal
    }

    func transactionsSubject(contractAddress: Data) throws -> PublishSubject<[TransactionInfo]> {
        return try token(contractAddress: contractAddress).transactionsSubject
    }

    func register(contractAddress: Data, balancePosition: Int, balance: TokenBalance) {
        let token = Token(contractAddress: contractAddress, balancePosition: balancePosition, balance: balance)

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
        let balancePosition: Int

        var balance: TokenBalance
        var syncState: Erc20Kit.SyncState = .notSynced

        let syncStateSignal = Signal()
        let balanceSignal = Signal()
        let transactionsSubject = PublishSubject<[TransactionInfo]>()

        init(contractAddress: Data, balancePosition: Int, balance: TokenBalance) {
            self.contractAddress = contractAddress
            self.balancePosition = balancePosition
            self.balance = balance
        }

    }

}

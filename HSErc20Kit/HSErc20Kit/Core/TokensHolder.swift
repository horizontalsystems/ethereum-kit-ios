class TokensHolder {

    var tokens = [Data: Token]()

}

extension TokensHolder: ITokensHolder {

    func add(token: Token) {
        tokens[token.contractAddress] = token
    }

    func token(byContractAddress contractAddress: Data) -> Token? {
        return tokens[contractAddress]
    }

    func clear() {
        tokens.removeAll()
    }

}

class PairSelector {
    private let tokenFactory: TokenFactory

    init(tokenFactory: TokenFactory) {
        self.tokenFactory = tokenFactory
    }

    func tokenPairs(tokenA: Token, tokenB: Token) -> [(Token, Token)] {
        if tokenA.isEther || tokenB.isEther {
            return [(tokenA, tokenB)]
        } else {
            let etherToken = tokenFactory.etherToken

            return [(tokenA, tokenB), (tokenA, etherToken), (tokenB, etherToken)]
        }
    }

}

import BigInt

struct Route {
    let pairs: [Pair]
    let path: [Token]
    let midPrice: Price

    init(pairs: [Pair], tokenIn: Token, tokenOut: Token) throws {
        guard !pairs.isEmpty else {
            throw Kit.RouteError.emptyPairs
        }

        var path = [tokenIn]
        var currentTokenIn = tokenIn

        for (index, pair) in pairs.enumerated() {
            guard pair.involves(token: currentTokenIn) else {
                throw Kit.RouteError.invalidPair(index: index)
            }

            let currentTokenOut = pair.other(token: currentTokenIn)
            path.append(currentTokenOut)
            currentTokenIn = currentTokenOut

            if index == pairs.count - 1 {
                guard currentTokenOut == tokenOut else {
                    throw Kit.RouteError.invalidPair(index: index)
                }
            }
        }

        self.pairs = pairs
        self.path = path

        var prices = [Price]()

        for (index, pair) in pairs.enumerated() {
            let price = path[index] == pair.token0 ?
                    Price(baseTokenAmount: pair.reserve0, quoteTokenAmount: pair.reserve1) :
                    Price(baseTokenAmount: pair.reserve1, quoteTokenAmount: pair.reserve0)

            prices.append(price)
        }

        midPrice = prices.dropFirst().reduce(prices[0]) { $0 * $1 }
    }

}

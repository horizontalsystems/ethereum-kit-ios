struct Route {
    let pairs: [Pair]
    let path: [Token]
//    let tokenIn: Token
//    let tokenOut: Token
//    let midPrice: Double

    init(pairs: [Pair], tokenIn: Token, tokenOut: Token) throws {
        guard !pairs.isEmpty else {
            throw InitError.emptyPairs
        }

        var path = [tokenIn]
        var currentTokenIn = tokenIn

        for (index, pair) in pairs.enumerated() {
            guard pair.involves(token: currentTokenIn) else {
                throw InitError.invalidPair(index: index)
            }

            let currentTokenOut = pair.other(token: currentTokenIn)
            path.append(currentTokenOut)
            currentTokenIn = currentTokenOut

            if index == pairs.count - 1 {
                guard currentTokenOut == tokenOut else {
                    throw InitError.invalidPair(index: index)
                }
            }
        }

        self.pairs = pairs
        self.path = path
    }

}

extension Route {

    enum InitError: Error {
        case emptyPairs
        case invalidPair(index: Int)
    }

}

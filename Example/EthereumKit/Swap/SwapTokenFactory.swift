import UniswapKit

class SwapTokenFactory {

    func uniswapToken(swapToken: SwapToken) -> UniswapKit.Token {
        switch swapToken {
        case .eth(let address): return UniswapKit.Token.eth(wethAddress: address)
        case .erc20(let address, let decimals): return UniswapKit.Token.erc20(address: address, decimals: decimals)
        }
    }

    func swapToken(uniswapToken: UniswapKit.Token) -> SwapToken {
        switch uniswapToken {
        case .eth(let address): return SwapToken.eth(wethAddress: address)
        case .erc20(let address, let decimals): return SwapToken.erc20(address: address, decimals: decimals)
        }
    }

}

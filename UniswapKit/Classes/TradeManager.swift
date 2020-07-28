import RxSwift
import BigInt
import EthereumKit
import OpenSslKit

class TradeManager {
    static let routerAddress = try! Address(hex: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")

    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let address: Address

    init(ethereumKit: EthereumKit.Kit, address: Address) {
        self.ethereumKit = ethereumKit
        self.address = address
    }

    private func buildSwapData(tradeData: TradeData) -> SwapData {
        let methodName: String
        let arguments: [ContractMethod.Argument]
        let amount: BigUInt

        let trade = tradeData.trade

        let tokenIn = trade.tokenAmountIn.token
        let tokenOut = trade.tokenAmountOut.token

        let path: ContractMethod.Argument = .addresses(trade.route.path.map { $0.address })
        let to: ContractMethod.Argument = .address(tradeData.options.recipient ?? address)
        let deadline: ContractMethod.Argument = .uint256(BigUInt(Date().timeIntervalSince1970 + tradeData.options.ttl))

        switch trade.type {
        case .exactIn:
            let amountIn = trade.tokenAmountIn.rawAmount
            let amountOutMin = tradeData.tokenAmountOutMin.rawAmount

            amount = amountIn

            switch (tokenIn, tokenOut) {
            case (.eth, .erc20):
                methodName = tradeData.options.feeOnTransfer ? "swapExactETHForTokensSupportingFeeOnTransferTokens" : "swapExactETHForTokens"
                arguments = [.uint256(amountOutMin), path, to, deadline]
            case (.erc20, .eth):
                methodName = tradeData.options.feeOnTransfer ? "swapExactTokensForETHSupportingFeeOnTransferTokens" : "swapExactTokensForETH"
                arguments = [.uint256(amountIn), .uint256(amountOutMin), path, to, deadline]
            case (.erc20, .erc20):
                methodName = tradeData.options.feeOnTransfer ? "swapExactTokensForTokensSupportingFeeOnTransferTokens" : "swapExactTokensForTokens"
                arguments = [.uint256(amountIn), .uint256(amountOutMin), path, to, deadline]
            default: fatalError()
            }

        case .exactOut:
            let amountOut = trade.tokenAmountOut.rawAmount
            let amountInMax = tradeData.tokenAmountInMax.rawAmount

            amount = amountInMax

            switch (tokenIn, tokenOut) {
            case (.eth, .erc20):
                methodName = "swapETHForExactTokens"
                arguments = [.uint256(amountOut), path, to, deadline]
            case (.erc20, .eth):
                methodName = "swapTokensForExactETH"
                arguments = [.uint256(amountOut), .uint256(amountInMax), path, to, deadline]
            case (.erc20, .erc20):
                methodName = "swapTokensForExactTokens"
                arguments = [.uint256(amountOut), .uint256(amountInMax), path, to, deadline]
            default: fatalError()
            }
        }

        let method = ContractMethod(name: methodName, arguments: arguments)

        if tokenIn.isEther {
            return SwapData(amount: amount, input: method.encodedData)
        } else {
            return SwapData(amount: 0, input: method.encodedData)
        }
    }

}

extension TradeManager {

    func pairSingle(tokenA: Token, tokenB: Token) -> Single<Pair> {
        let method = ContractMethod(name: "getReserves")

        let (token0, token1) = tokenA.sortsBefore(token: tokenB) ? (tokenA, tokenB) : (tokenB, tokenA)

        let pairAddress = Pair.address(token0: token0, token1: token1)

//        print("PAIR ADDRESS: \(pairAddress.toHexString())")

        return self.ethereumKit.call(contractAddress: pairAddress, data: method.encodedData)
                .map { data in
//                    print("DATA: \(data.toHexString())")

                    var rawReserve0: BigUInt = 0
                    var rawReserve1: BigUInt = 0

                    if data.count == 3 * 32 {
                        rawReserve0 = BigUInt(data[0...31])
                        rawReserve1 = BigUInt(data[32...63])
                    }

//                    print("Reserve0: \(reserve0), Reserve1: \(reserve1)")

                    let reserve0 = TokenAmount(token: token0, rawAmount: rawReserve0)
                    let reserve1 = TokenAmount(token: token1, rawAmount: rawReserve1)

                    return Pair(reserve0: reserve0, reserve1: reserve1)
                }
    }

    func estimateSwapSingle(tradeData: TradeData, gasPrice: Int) -> Single<Int> {
        let swapData = buildSwapData(tradeData: tradeData)

        return ethereumKit.estimateGas(
                to: TradeManager.routerAddress,
                amount: swapData.amount == 0 ? nil : swapData.amount,
                gasPrice: gasPrice,
                data: swapData.input
        )
    }

    func swapSingle(tradeData: TradeData, gasLimit: Int, gasPrice: Int) -> Single<String> {
        let swapData = buildSwapData(tradeData: tradeData)

        return ethereumKit.sendSingle(
                        address: TradeManager.routerAddress,
                        value: swapData.amount,
                        transactionInput: swapData.input,
                        gasPrice: gasPrice,
                        gasLimit: gasLimit
                )
                .map { txInfo in
                    txInfo.hash
                }
    }

}

extension TradeManager {

    private struct SwapData {
        let amount: BigUInt
        let input: Data
    }

}

extension TradeManager {

    static func tradesExactIn(pairs: [Pair], tokenAmountIn: TokenAmount, tokenOut: Token, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountIn: TokenAmount? = nil) throws -> [Trade] {
        // todo: guards

        var trades = [Trade]()
        let originalTokenAmountIn = originalTokenAmountIn ?? tokenAmountIn

        for (index, pair) in pairs.enumerated() {
            let tokenAmountOut: TokenAmount

            do {
                tokenAmountOut = try pair.tokenAmountOut(tokenAmountIn: tokenAmountIn)
            } catch {
                continue
            }

            if tokenAmountOut.token == tokenOut {
                let trade = Trade(
                        type: .exactIn,
                        route: try Route(pairs: currentPairs + [pair], tokenIn: originalTokenAmountIn.token, tokenOut: tokenOut),
                        tokenAmountIn: originalTokenAmountIn,
                        tokenAmountOut: tokenAmountOut
                )

                trades.append(trade)
            } else if maxHops > 1 && pairs.count > 1 {
                let pairsExcludingThisPair = Array(pairs[0..<index] + pairs[(index + 1)..<pairs.count])

                let recursiveTrades = try TradeManager.tradesExactIn(
                        pairs: pairsExcludingThisPair,
                        tokenAmountIn: tokenAmountOut,
                        tokenOut: tokenOut,
                        maxHops: maxHops - 1,
                        currentPairs: currentPairs + [pair],
                        originalTokenAmountIn: originalTokenAmountIn
                )

                trades.append(contentsOf: recursiveTrades)
            }
        }

        return trades
    }

    static func tradesExactOut(pairs: [Pair], tokenIn: Token, tokenAmountOut: TokenAmount, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountOut: TokenAmount? = nil) throws -> [Trade] {
        // todo: guards

        var trades = [Trade]()
        let originalTokenAmountOut = originalTokenAmountOut ?? tokenAmountOut

        for (index, pair) in pairs.enumerated() {
            let tokenAmountIn: TokenAmount

            do {
                tokenAmountIn = try pair.tokenAmountIn(tokenAmountOut: tokenAmountOut)
            } catch {
                continue
            }

            if tokenAmountIn.token == tokenIn {
                let trade = Trade(
                        type: .exactOut,
                        route: try Route(pairs: [pair] + currentPairs, tokenIn: tokenIn, tokenOut: originalTokenAmountOut.token),
                        tokenAmountIn: tokenAmountIn,
                        tokenAmountOut: originalTokenAmountOut
                )

                trades.append(trade)
            } else if maxHops > 1 && pairs.count > 1 {
                let pairsExcludingThisPair = Array(pairs[0..<index] + pairs[(index + 1)..<pairs.count])

                let recursiveTrades = try TradeManager.tradesExactOut(
                        pairs: pairsExcludingThisPair,
                        tokenIn: tokenIn,
                        tokenAmountOut: tokenAmountIn,
                        maxHops: maxHops - 1,
                        currentPairs: [pair] + currentPairs,
                        originalTokenAmountOut: originalTokenAmountOut
                )

                trades.append(contentsOf: recursiveTrades)
            }
        }

        return trades
    }

}

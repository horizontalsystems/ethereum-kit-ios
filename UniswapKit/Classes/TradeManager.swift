import RxSwift
import BigInt
import EthereumKit
import OpenSslKit

class TradeManager {
    public let routerAddress: Address

    private let disposeBag = DisposeBag()
    private let evmKit: EthereumKit.Kit
    private let address: Address

    init(evmKit: EthereumKit.Kit, address: Address) {
        routerAddress = TradeManager.routerAddress(networkType: evmKit.networkType)

        self.evmKit = evmKit
        self.address = address
    }

    private func buildSwapData(tradeData: TradeData) throws -> SwapData {
        let trade = tradeData.trade

        let tokenIn = trade.tokenAmountIn.token
        let tokenOut = trade.tokenAmountOut.token

        let path = trade.route.path.map {
            $0.address
        }
        let to = tradeData.options.recipient ?? address
        let deadline = BigUInt(Date().timeIntervalSince1970 + tradeData.options.ttl)

        let method: ContractMethod
        var amount: BigUInt

        switch trade.type {
        case .exactIn:
            amount = tokenIn.isEther ? trade.tokenAmountIn.rawAmount : 0
            method = try buildMethodForExactIn(tokenIn: tokenIn, tokenOut: tokenOut, path: path, to: to, deadline: deadline, tradeData: tradeData, trade: trade)
        case .exactOut:
            amount = tokenIn.isEther ? tradeData.tokenAmountInMax.rawAmount : 0
            method = try buildMethodForExactOut(tokenIn: tokenIn, tokenOut: tokenOut, path: path, to: to, deadline: deadline, tradeData: tradeData)
        }

        return SwapData(amount: amount, input: method.encodedABI())
    }

    private func buildMethodForExactOut(tokenIn: Token, tokenOut: Token, path: [Address], to: Address, deadline: BigUInt, tradeData: TradeData) throws -> ContractMethod {
        let amountInMax = tradeData.tokenAmountInMax.rawAmount
        let amountOut = tradeData.trade.tokenAmountOut.rawAmount

        guard tokenIn != tokenOut else {
            throw Kit.TradeError.invalidTokensForSwap
        }

        switch tokenIn {
        case .eth: return SwapETHForExactTokensMethod(amountOut: amountOut, path: path, to: to, deadline: deadline)
        case .erc20:
            if case .eth = tokenOut {
                return SwapTokensForExactETHMethod(amountOut: amountOut, amountInMax: amountInMax, path: path, to: to, deadline: deadline)
            }
            return SwapTokensForExactTokensMethod(amountOut: amountOut, amountInMax: amountInMax, path: path, to: to, deadline: deadline)
        }

    }

    private func buildMethodForExactIn(tokenIn: Token, tokenOut: Token, path: [Address], to: Address, deadline: BigUInt, tradeData: TradeData, trade: Trade) throws -> ContractMethod {
        let amountIn = trade.tokenAmountIn.rawAmount
        let amountOutMin = tradeData.tokenAmountOutMin.rawAmount
        let supportingFeeOnTransfer = tradeData.options.feeOnTransfer

        guard tokenIn != tokenOut else {
            throw Kit.TradeError.invalidTokensForSwap
        }

        switch tokenIn {
        case .eth: return SwapExactETHForTokensMethod(amountOut: amountOutMin, path: path, to: to, deadline: deadline, supportingFeeOnTransfer: supportingFeeOnTransfer)
        case .erc20:
            if case .eth = tokenOut {
                return SwapExactTokensForETHMethod(amountIn: amountIn, amountOutMin: amountOutMin, path: path, to: to, deadline: deadline, supportingFeeOnTransfer: supportingFeeOnTransfer)
            }
            return SwapExactTokensForTokensMethod(amountIn: amountIn, amountOutMin: amountOutMin, path: path, to: to, deadline: deadline, supportingFeeOnTransfer: supportingFeeOnTransfer)
        }
    }

}

extension TradeManager {

    func pairSingle(tokenA: Token, tokenB: Token) -> Single<Pair> {
        let (token0, token1) = tokenA.sortsBefore(token: tokenB) ? (tokenA, tokenB) : (tokenB, tokenA)

        let pairAddress = Pair.address(token0: token0, token1: token1, networkType: evmKit.networkType)

//        print("PAIR ADDRESS: \(pairAddress.toHexString())")

        return evmKit.call(contractAddress: pairAddress, data: GetReservesMethod().encodedABI())
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

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        let swapData = try buildSwapData(tradeData: tradeData)

        return TransactionData(
                to: routerAddress,
                value: swapData.amount,
                input: swapData.input
        )
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

    static func routerAddress(networkType: EthereumKit.NetworkType) -> Address {
        switch networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return try! Address(hex: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")
        case .bscMainNet: return try! Address(hex: "0x10ED43C718714eb63d5aA57B78B54704E256024E")
        }
    }


}

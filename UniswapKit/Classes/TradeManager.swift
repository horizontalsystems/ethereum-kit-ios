import RxSwift
import BigInt
import EthereumKit
import OpenSslKit

class TradeManager {
    public let routerAddress: Address
    private let factoryAddressString: String
    private let initCodeHashString: String

    private let evmKit: EthereumKit.Kit
    private let address: Address

    init(evmKit: EthereumKit.Kit, address: Address) throws {
        routerAddress = try Self.routerAddress(chain: evmKit.chain)
        factoryAddressString = try Self.factoryAddressString(chain: evmKit.chain)
        initCodeHashString = try Self.initCodeHashString(chain: evmKit.chain)

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

        let pairAddress = Pair.address(token0: token0, token1: token1, factoryAddressString: factoryAddressString, initCodeHashString: initCodeHashString)

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

    public enum UnsupportedChainError: Error {
        case noRouterAddress
        case noFactoryAddress
        case noInitCodeHash
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

    private static func routerAddress(chain: Chain) throws -> Address {
        switch chain.id {
        case 1, 3, 4, 5, 42: return try Address(hex: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")
        case 56: return try Address(hex: "0x10ED43C718714eb63d5aA57B78B54704E256024E")
        case 137: return try Address(hex: "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff")
        case 43114: return try Address(hex: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4")
        default: throw UnsupportedChainError.noRouterAddress
        }
    }

    private static func factoryAddressString(chain: Chain) throws -> String {
        switch chain.id {
        case 1, 3, 4, 5, 42: return "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
        case 56: return "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
        case 137: return "0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32"
        case 43114: return "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10"
        default: throw UnsupportedChainError.noFactoryAddress
        }
    }

    private static func initCodeHashString(chain: Chain) throws -> String {
        switch chain.id {
        case 1, 3, 4, 5, 42: return "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
        case 56: return "0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5"
        case 137: return "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
        case 43114: return "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
        default: throw UnsupportedChainError.noInitCodeHash
        }
    }

}

import RxSwift
import BigInt
import EthereumKit
import OpenSslKit

class TradeManager {
    private static let routerAddress = Data(hex: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")!

    private let scheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "transactionManager.handle_logs", qos: .background))
    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let address: Data

    init(ethereumKit: EthereumKit.Kit, address: Data) throws {
        self.ethereumKit = ethereumKit
        self.address = address
    }

    private func swapSingle(value: BigUInt, input: Data) -> Single<String> {
        ethereumKit.sendSingle(
                        address: TradeManager.routerAddress,
                        value: value,
                        transactionInput: input,
                        gasPrice: 50_000_000_000,
                        gasLimit: 500_000
                )
                .map { txInfo in
                    txInfo.hash
                }
    }

    private func singleWithApprove(contractAddress: Data, amount: BigUInt, single: Single<String>) -> Single<String> {
        let method = ContractMethod(name: "approve", arguments: [
            .address(TradeManager.routerAddress),
            .uint256(amount)
        ])

        return ethereumKit.sendSingle(
                        address: contractAddress,
                        value: 0,
                        transactionInput: method.encodedData,
                        gasPrice: 50_000_000_000,
                        gasLimit: 500_000
                )
                .flatMap { txInfo in
                    print("APPROVE TX: \(txInfo.hash)")
                    return single
                }
    }

}

extension TradeManager {

    func pairSingle(tokenA: Token, tokenB: Token) -> Single<Pair> {
        let method = ContractMethod(name: "getReserves")

        let (token0, token1) = tokenA.sortsBefore(token: tokenB) ? (tokenA, tokenB) : (tokenB, tokenA)

        let pairAddress = Pair.address(token0: token0, token1: token1)

        print("PAIR ADDRESS: \(pairAddress.toHexString())")

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

    func swapSingle(tradeData: TradeData) -> Single<String> {
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
            return swapSingle(value: amount, input: method.encodedData)
        } else {
            return singleWithApprove(
                    contractAddress: tokenIn.address,
                    amount: amount,
                    single: swapSingle(value: 0, input: method.encodedData)
            )
        }
    }

}

extension TradeManager {

    static func bestTradeExactIn(pairs: [Pair], tokenAmountIn: TokenAmount, tokenOut: Token, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountIn: TokenAmount? = nil) throws -> [Trade] {
        // todo: guards

        var bestTrades = [Trade]()
        let originalTokenAmountIn = originalTokenAmountIn ?? tokenAmountIn
        let tokenIn = tokenAmountIn.token

        for (index, pair) in pairs.enumerated() {
            guard pair.token0 == tokenIn || pair.token1 == tokenIn else {
                continue
            }

            guard pair.reserve0.rawAmount != 0 && pair.reserve1.rawAmount != 0 else {
                continue
            }

            let tokenAmountOut = pair.tokenAmountOut(tokenAmountIn: tokenAmountIn)

            if tokenAmountOut.token == tokenOut {
                let trade = Trade(
                        type: .exactIn,
                        route: try Route(pairs: currentPairs + [pair], tokenIn: originalTokenAmountIn.token, tokenOut: tokenOut),
                        tokenAmountIn: originalTokenAmountIn,
                        tokenAmountOut: tokenAmountOut
                )

                bestTrades.append(trade)
            } else if maxHops > 1 && pairs.count > 1 {
                let pairsExcludingThisPair = Array(pairs[0..<index] + pairs[(index + 1)..<pairs.count])

                let trades = try TradeManager.bestTradeExactIn(
                        pairs: pairsExcludingThisPair,
                        tokenAmountIn: tokenAmountOut,
                        tokenOut: tokenOut,
                        maxHops: maxHops - 1,
                        currentPairs: currentPairs + [pair],
                        originalTokenAmountIn: originalTokenAmountIn
                )

                bestTrades.append(contentsOf: trades)
            }
        }

        return bestTrades
    }

    static func bestTradeExactOut(pairs: [Pair], tokenIn: Token, tokenAmountOut: TokenAmount, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountOut: TokenAmount? = nil) throws -> [Trade] {
        // todo: guards

        var bestTrades = [Trade]()
        let originalTokenAmountOut = originalTokenAmountOut ?? tokenAmountOut
        let tokenOut = tokenAmountOut.token

        for (index, pair) in pairs.enumerated() {
            guard pair.token0 == tokenOut || pair.token1 == tokenOut else {
                continue
            }

            guard pair.reserve0.rawAmount != 0 && pair.reserve1.rawAmount != 0 else {
                continue
            }

            guard let tokenAmountIn = try? pair.tokenAmountIn(tokenAmountOut: tokenAmountOut) else {
                continue
            }

            if tokenAmountIn.token == tokenIn {
                let trade = Trade(
                        type: .exactOut,
                        route: try Route(pairs: [pair] + currentPairs, tokenIn: tokenIn, tokenOut: originalTokenAmountOut.token),
                        tokenAmountIn: tokenAmountIn,
                        tokenAmountOut: originalTokenAmountOut
                )

                bestTrades.append(trade)
            } else if maxHops > 1 && pairs.count > 1 {
                let pairsExcludingThisPair = Array(pairs[0..<index] + pairs[(index + 1)..<pairs.count])

                let trades = try TradeManager.bestTradeExactOut(
                        pairs: pairsExcludingThisPair,
                        tokenIn: tokenIn,
                        tokenAmountOut: tokenAmountIn,
                        maxHops: maxHops - 1,
                        currentPairs: [pair] + currentPairs,
                        originalTokenAmountOut: originalTokenAmountOut
                )

                bestTrades.append(contentsOf: trades)
            }
        }

        return bestTrades
    }

}

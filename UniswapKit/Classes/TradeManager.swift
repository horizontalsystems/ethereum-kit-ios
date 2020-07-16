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

    private func approveMethod(amount: BigUInt) -> ContractMethod {
        ContractMethod(name: "approve", arguments: [
            .address(TradeManager.routerAddress),
            .uint256(amount)
        ])
    }

    private func swapSingle(swapData: SwapData, gasData: GasData, gasPrice: Int) -> Single<String> {
        let swapSingle = ethereumKit.sendSingle(
                        address: TradeManager.routerAddress,
                        value: swapData.amount,
                        transactionInput: swapData.input,
                        gasPrice: gasPrice,
                        gasLimit: gasData.swapGas
                )
                .map { txInfo in
                    txInfo.hash
                }

        if let approveData = swapData.approveData {
            return ethereumKit.sendSingle(
                            address: approveData.contractAddress,
                            value: 0,
                            transactionInput: approveMethod(amount: approveData.amount).encodedData,
                            gasPrice: gasPrice,
                            gasLimit: gasData.approveGas
                    )
                    .flatMap { txInfo in
                        print("APPROVE TX: \(txInfo.hash)")
                        return swapSingle
                    }
        } else {
            return swapSingle
        }
    }

    private func estimateSwapSingle(swapData: SwapData, gasPrice: Int) -> Single<GasData> {
        let estimateSwapSingle = ethereumKit.estimateGas(
                to: TradeManager.routerAddress,
                amount: swapData.amount == 0 ? nil : swapData.amount,
                gasPrice: gasPrice,
                data: swapData.input
        )

        if let approveData = swapData.approveData {
            let estimateApproveSingle = ethereumKit.estimateGas(
                    to: approveData.contractAddress,
                    amount: nil,
                    gasPrice: gasPrice,
                    data: approveMethod(amount: approveData.amount).encodedData
            )

            return Single.zip(estimateSwapSingle, estimateApproveSingle) { swapGas, approveGas -> GasData in
                GasData(swapGas: swapGas, approveGas: approveGas)
            }
        } else {
            return estimateSwapSingle.map { swapGas in
                GasData(swapGas: swapGas)
            }
        }
    }

    private func swapData(tradeData: TradeData) -> SwapData {
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
            return SwapData(amount: amount, input: method.encodedData, approveData: nil)
        } else {
            return SwapData(
                    amount: 0,
                    input: method.encodedData,
                    approveData: ApproveData(contractAddress: tokenIn.address, amount: amount)
            )
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

    func estimateGasSingle(tradeData: TradeData, gasPrice: Int) -> Single<GasData> {
        estimateSwapSingle(swapData: swapData(tradeData: tradeData), gasPrice: gasPrice)
    }

    func swapSingle(tradeData: TradeData, gasData: GasData, gasPrice: Int) -> Single<String> {
        swapSingle(swapData: swapData(tradeData: tradeData), gasData: gasData, gasPrice: gasPrice)
    }

}

extension TradeManager {

    private struct SwapData {
        let amount: BigUInt
        let input: Data
        var approveData: ApproveData?
    }

    private struct ApproveData {
        let contractAddress: Data
        let amount: BigUInt
    }

}

extension TradeManager {

    static func bestTradeExactIn(pairs: [Pair], tokenAmountIn: TokenAmount, tokenOut: Token, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountIn: TokenAmount? = nil) throws -> [Trade] {
        // todo: guards

        var bestTrades = [Trade]()
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

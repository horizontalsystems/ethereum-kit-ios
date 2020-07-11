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

//        print("PAIR ADDRESS: \(pairAddress.toHexString())")

        return self.ethereumKit.call(contractAddress: pairAddress, data: method.encodedData)
                .map { data in
//                    print("DATA: \(data.toHexString())")

                    var reserve0: BigUInt = 0
                    var reserve1: BigUInt = 0

                    if data.count == 3 * 32 {
                        reserve0 = BigUInt(data[0...31])
                        reserve1 = BigUInt(data[32...63])
                    }

//                    print("Reserve0: \(reserve0), Reserve1: \(reserve1)")

                    let tokenAmount0 = TokenAmount(token: token0, amount: reserve0)
                    let tokenAmount1 = TokenAmount(token: token1, amount: reserve1)

                    return Pair(tokenAmount0: tokenAmount0, tokenAmount1: tokenAmount1)
                }
    }

    func swapSingle(tradeData: TradeData) -> Single<String> {
        let methodName: String
        let arguments: [ContractMethod.Argument]
        let amount: BigUInt

        let trade = tradeData.trade

        let tokenIn = trade.tokenAmountIn.token
        let tokenOut = trade.tokenAmountOut.token

        let path: ContractMethod.Argument = .addresses([tokenIn, tokenOut].map { $0.address }) // todo: compute path in Route
        let to: ContractMethod.Argument = .address(tradeData.options.recipient ?? address)
        let deadline: ContractMethod.Argument = .uint256(BigUInt(Date().timeIntervalSince1970 + tradeData.options.ttl))

        switch trade.type {
        case .exactIn:
            let amountIn = trade.tokenAmountIn.amount
            let amountOutMin = tradeData.tokenAmountOutMin.amount

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
            let amountOut = trade.tokenAmountOut.amount
            let amountInMax = tradeData.tokenAmountInMax.amount

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

    static func bestTradeExactIn(pairs: [Pair], tokenAmountIn: TokenAmount, tokenOut: Token, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountIn: TokenAmount? = nil, bestTrade: Trade? = nil) -> Trade? {
        // todo: guards

        let originalTokenAmountIn = originalTokenAmountIn ?? tokenAmountIn
        let tokenIn = tokenAmountIn.token

        for pair in pairs {
            guard pair.token0 == tokenIn || pair.token1 == tokenIn else {
                continue
            }

            guard pair.reserve0 != 0 && pair.reserve1 != 0 else {
                continue
            }

            let tokenAmountOut = pair.tokenAmountOut(tokenAmountIn: tokenAmountIn)

            if tokenAmountOut.token == tokenOut {
                return Trade(
                        type: .exactIn,
                        route: Route(pairs: currentPairs + [pair]),
                        tokenAmountIn: originalTokenAmountIn,
                        tokenAmountOut: tokenAmountOut
                )
            } else if maxHops > 1 && pairs.count > 1 {
                // todo
            }
        }

        return nil
    }

    static func bestTradeExactOut(pairs: [Pair], tokenIn: Token, tokenAmountOut: TokenAmount, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountOut: TokenAmount? = nil, bestTrade: Trade? = nil) -> Trade? {
        // todo: guards

        let originalTokenAmountOut = originalTokenAmountOut ?? tokenAmountOut
        let tokenOut = tokenAmountOut.token

        for pair in pairs {
            guard pair.token0 == tokenOut || pair.token1 == tokenOut else {
                continue
            }

            guard pair.reserve0 != 0 && pair.reserve1 != 0 else {
                continue
            }

            guard let tokenAmountIn = try? pair.tokenAmountIn(tokenAmountOut: tokenAmountOut) else {
                continue
            }

            if tokenAmountIn.token == tokenIn {
                return Trade(
                        type: .exactOut,
                        route: Route(pairs: [pair] + currentPairs),
                        tokenAmountIn: tokenAmountIn,
                        tokenAmountOut: originalTokenAmountOut
                )
            } else if maxHops > 1 && pairs.count > 1 {
                // todo
            }
        }

        return nil
    }

}

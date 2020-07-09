import RxSwift
import BigInt
import EthereumKit
import OpenSslKit

class TradeManager {
    private static let uniswapRouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"

    private let scheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "transactionManager.handle_logs", qos: .background))
    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let routerAddress: Data
    private let address: Data

    init(ethereumKit: EthereumKit.Kit, address: Data) throws {
        self.ethereumKit = ethereumKit
        self.address = address

        guard let routerAddress = Data(hex: TradeManager.uniswapRouterAddress) else {
            throw Kit.KitError.invalidAddress
        }

        self.routerAddress = routerAddress
    }

    private var deadline: BigUInt {
        BigUInt(Date().timeIntervalSince1970 + 3600)
    }

    private func swapSingle(value: BigUInt, input: Data) -> Single<String> {
        ethereumKit.sendSingle(
                        address: routerAddress,
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
        let approveTransactionInput = ERC20.ContractFunctions.approve(spender: routerAddress, amount: amount)

        return ethereumKit.sendSingle(
                        address: contractAddress,
                        value: 0,
                        transactionInput: approveTransactionInput.data,
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

    func pairsSingle(tokenIn: Token, tokenOut: Token) -> Single<[Pair]> {
        let transactionInput = Uniswap.ContractFunctions.getReserves

        let (token0, token1) = tokenIn.sortsBefore(token: tokenOut) ? (tokenIn, tokenOut) : (tokenOut, tokenIn)

        let pairAddress = Pair.address(token0: token0, token1: token1)

        print("PAIR ADDRESS: \(pairAddress.toHexString())")

        return self.ethereumKit.call(contractAddress: pairAddress, data: transactionInput.data)
                .flatMap { data in
                    print("DATA: \(data.toHexString())")

                    let reserve0 = BigUInt(data[0...31])
                    let reserve1 = BigUInt(data[32...63])

                    print("Reserve0: \(reserve0), Reserve1: \(reserve1)")

                    let tokenAmount0 = TokenAmount(token: token0, amount: reserve0)
                    let tokenAmount1 = TokenAmount(token: token1, amount: reserve1)

                    let pair = Pair(tokenAmount0: tokenAmount0, tokenAmount1: tokenAmount1)

                    return Single.just([pair])
                }
    }

    func swapExactETHForTokens(amountIn: BigUInt, amountOutMin: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapExactETHForTokens(
                amountOutMin: amountOutMin,
                path: path,
                to: address,
                deadline: deadline
        )

        return swapSingle(value: amountIn, input: transactionInput.data)
    }

    func swapTokensForExactETH(amountOut: BigUInt, amountInMax: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapTokensForExactETH(
                amountOut: amountOut,
                amountInMax: amountInMax,
                path: path,
                to: address,
                deadline: deadline
        )

        return singleWithApprove(
                contractAddress: path[0],
                amount: amountInMax,
                single: swapSingle(value: 0, input: transactionInput.data)
        )
    }

    func swapExactTokensForETH(amountIn: BigUInt, amountOutMin: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapExactTokensForETH(
                amountIn: amountIn,
                amountOutMin: amountOutMin,
                path: path,
                to: address,
                deadline: deadline
        )

        return singleWithApprove(
                contractAddress: path[0],
                amount: amountIn,
                single: swapSingle(value: 0, input: transactionInput.data)
        )
    }

    func swapETHForExactTokens(amountOut: BigUInt, amountInMax: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapETHForExactTokens(
                amountOut: amountOut,
                path: path,
                to: address,
                deadline: deadline
        )

        return swapSingle(value: amountInMax, input: transactionInput.data)
    }

    func swapExactTokensForTokens(amountIn: BigUInt, amountOutMin: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapExactTokensForTokens(
                amountIn: amountIn,
                amountOutMin: amountOutMin,
                path: path,
                to: address,
                deadline: deadline
        )

        return singleWithApprove(
                contractAddress: path[0],
                amount: amountIn,
                single: swapSingle(value: 0, input: transactionInput.data)
        )
    }

    func swapTokensForExactTokens(amountOut: BigUInt, amountInMax: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapTokensForExactTokens(
                amountOut: amountOut,
                amountInMax: amountInMax,
                path: path,
                to: address,
                deadline: deadline
        )

        return singleWithApprove(
                contractAddress: path[0],
                amount: amountInMax,
                single: swapSingle(value: 0, input: transactionInput.data)
        )
    }

}

extension TradeManager {

    enum ContractError: Error {
        case invalidResponse
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

            let tokenAmountIn = pair.tokenAmountIn(tokenAmountOut: tokenAmountOut)

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

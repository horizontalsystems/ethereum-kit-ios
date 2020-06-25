import RxSwift
import BigInt
import EthereumKit

class TradeManager {
    private let scheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "transactionManager.handle_logs", qos: .background))
    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let routerAddress: Data
    private let address: Data

    init(ethereumKit: EthereumKit.Kit, routerAddress: Data, address: Data) {
        self.ethereumKit = ethereumKit
        self.routerAddress = routerAddress
        self.address = address
    }

    private static func decodeAmounts(data: Data, pathCount: Int) throws -> [BigUInt] {
        guard data.count == 64 + pathCount * 32 else {
            throw ContractError.invalidResponse
        }

        return (0..<pathCount).map { i in
            BigUInt(data[64 + i * 32...64 + (i + 1) * 32 - 1])
        }
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

    func amountsOutSingle(amountIn: BigUInt, path: [Data]) -> Single<[BigUInt]> {
        let transactionInput = Uniswap.ContractFunctions.getAmountsOut(amountIn: amountIn, path: path)

        return ethereumKit.call(contractAddress: routerAddress, data: transactionInput.data)
                .flatMap { data in
                    do {
                        return Single.just(try TradeManager.decodeAmounts(data: data, pathCount: path.count))
                    } catch {
                        return Single.error(error)
                    }
                }
    }

    func amountsInSingle(amountOut: BigUInt, path: [Data]) -> Single<[BigUInt]> {
        let transactionInput = Uniswap.ContractFunctions.getAmountsIn(amountOut: amountOut, path: path)

        return ethereumKit.call(contractAddress: routerAddress, data: transactionInput.data)
                .flatMap { data in
                    do {
                        return Single.just(try TradeManager.decodeAmounts(data: data, pathCount: path.count))
                    } catch {
                        return Single.error(error)
                    }
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

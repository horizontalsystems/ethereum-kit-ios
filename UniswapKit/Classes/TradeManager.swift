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

    func amountsOutSingle(amountIn: BigUInt, path: [Data]) -> Single<[BigUInt]> {
        let transactionInput = Uniswap.ContractFunctions.getAmountsOut(amountIn: amountIn, path: path)

        return ethereumKit.call(contractAddress: routerAddress, data: transactionInput.data)
                .flatMap { data in
                    guard data.count == 64 + path.count * 32 else {
                        return Single.error(ContractError.invalidResponse)
                    }

                    let amounts = (0..<path.count).map { i in
                        BigUInt(data[64 + i * 32...64 + (i + 1) * 32 - 1])
                    }

                    return Single.just(amounts)
                }
    }

    func amountsInSingle(amountOut: BigUInt, path: [Data]) -> Single<[BigUInt]> {
        let transactionInput = Uniswap.ContractFunctions.getAmountsIn(amountOut: amountOut, path: path)

        return ethereumKit.call(contractAddress: routerAddress, data: transactionInput.data)
                .flatMap { data in
                    guard data.count == 64 + path.count * 32 else {
                        return Single.error(ContractError.invalidResponse)
                    }

                    let amounts = (0..<path.count).map { i in
                        BigUInt(data[64 + i * 32...64 + (i + 1) * 32 - 1])
                    }

                    return Single.just(amounts)
                }
    }

    func swapExactETHForTokens(amountIn: BigUInt, amountOutMin: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapExactETHForTokens(
                amountOutMin: amountOutMin,
                path: path,
                to: address,
                deadline: BigUInt(Date().timeIntervalSince1970 + 3600)
        )

        return ethereumKit.sendSingle(
                        address: routerAddress,
                        value: amountIn,
                        transactionInput: transactionInput.data,
                        gasPrice: 50_000_000_000,
                        gasLimit: 500_000
                )
                .map { txInfo in
                    txInfo.hash
                }
    }

    func swapTokensForExactETH(amountOut: BigUInt, amountInMax: BigUInt, path: [Data]) -> Single<String> {
        let approveTransactionInput = ERC20.ContractFunctions.approve(spender: routerAddress, amount: amountInMax)

        let transactionInput = Uniswap.ContractFunctions.swapTokensForExactETH(
                amountOut: amountOut,
                amountInMax: amountInMax,
                path: path,
                to: address,
                deadline: BigUInt(Date().timeIntervalSince1970 + 3600)
        )

        return ethereumKit.sendSingle(
                        address: path[0],
                        value: 0,
                        transactionInput: approveTransactionInput.data,
                        gasPrice: 50_000_000_000,
                        gasLimit: 500_000
                )
                .flatMap { [unowned self] txInfo in
                    print("APPROVE TX: \(txInfo.hash)")

                    return self.ethereumKit.sendSingle(
                                    address: self.routerAddress,
                                    value: 0,
                                    transactionInput: transactionInput.data,
                                    gasPrice: 50_000_000_000,
                                    gasLimit: 500_000
                            )
                            .map { txInfo in
                                txInfo.hash
                            }
                }
    }

    func swapExactTokensForETH(amountIn: BigUInt, amountOutMin: BigUInt, path: [Data]) -> Single<String> {
        let approveTransactionInput = ERC20.ContractFunctions.approve(spender: routerAddress, amount: amountIn)

        let transactionInput = Uniswap.ContractFunctions.swapExactTokensForETH(
                amountIn: amountIn,
                amountOutMin: amountOutMin,
                path: path,
                to: address,
                deadline: BigUInt(Date().timeIntervalSince1970 + 3600)
        )

        return ethereumKit.sendSingle(
                        address: path[0],
                        value: 0,
                        transactionInput: approveTransactionInput.data,
                        gasPrice: 50_000_000_000,
                        gasLimit: 500_000
                )
                .flatMap { [unowned self] txInfo in
                    print("APPROVE TX: \(txInfo.hash)")

                    return self.ethereumKit.sendSingle(
                                    address: self.routerAddress,
                                    value: 0,
                                    transactionInput: transactionInput.data,
                                    gasPrice: 50_000_000_000,
                                    gasLimit: 500_000
                            )
                            .map { txInfo in
                                txInfo.hash
                            }
                }
    }

    func swapETHForExactTokens(amountOut: BigUInt, amountInMax: BigUInt, path: [Data]) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapETHForExactTokens(
                amountOut: amountOut,
                path: path,
                to: address,
                deadline: BigUInt(Date().timeIntervalSince1970 + 3600)
        )

        return ethereumKit.sendSingle(
                        address: routerAddress,
                        value: amountInMax,
                        transactionInput: transactionInput.data,
                        gasPrice: 50_000_000_000,
                        gasLimit: 500_000
                )
                .map { txInfo in
                    txInfo.hash
                }
    }

}

extension TradeManager {

    enum ContractError: Error {
        case invalidResponse
    }

}

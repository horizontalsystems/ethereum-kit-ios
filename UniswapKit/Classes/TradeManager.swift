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

    func swapExactETHForTokens(amount: BigUInt, amountOutMin: BigUInt, wethContractAddress: Data, toContractAddress: Data) -> Single<String> {
        let transactionInput = Uniswap.ContractFunctions.swapExactETHForTokens(
                amountOutMin: amountOutMin,
                path: [wethContractAddress, toContractAddress],
                to: address,
                deadline: BigUInt(Date().timeIntervalSince1970 + 3600)
        )

        return ethereumKit.sendSingle(
                        address: routerAddress,
                        value: amount,
                        transactionInput: transactionInput.data,
                        gasPrice: 50_000_000_000,
                        gasLimit: 500_000
                )
                .map { txInfo in
                    txInfo.hash
                }
    }

    func amountsOutSingle(amountIn: BigUInt, fromContractAddress: Data, toContractAddress: Data) -> Single<(BigUInt, BigUInt)> {
        let transactionInput = Uniswap.ContractFunctions.getAmountsOut(amountIn: amountIn, path: [fromContractAddress, toContractAddress])

        return ethereumKit.call(contractAddress: routerAddress, data: transactionInput.data)
                .flatMap { data in
                    guard data.count == 128 else {
                        return Single.error(ContractError.invalidResponse)
                    }

                    let amountIn = BigUInt(data[64...95])
                    let amountOut = BigUInt(data[96...127])

                    return Single.just((amountIn, amountOut))
                }
    }

    func amountsInSingle(amountOut: BigUInt, fromContractAddress: Data, toContractAddress: Data) -> Single<(BigUInt, BigUInt)> {
        let transactionInput = Uniswap.ContractFunctions.getAmountsIn(amountOut: amountOut, path: [fromContractAddress, toContractAddress])

        return ethereumKit.call(contractAddress: routerAddress, data: transactionInput.data)
                .flatMap { data in
                    guard data.count == 128 else {
                        return Single.error(ContractError.invalidResponse)
                    }

                    let amountIn = BigUInt(data[64...95])
                    let amountOut = BigUInt(data[96...127])

                    return Single.just((amountIn, amountOut))
                }
    }

}

extension TradeManager {

    enum ContractError: Error {
        case invalidResponse
    }

}

import Foundation
import EthereumKit
import UniswapKit
import RxSwift
import RxRelay

class UniswapService {
    private let disposeBag = DisposeBag()
    private let uniswapKit: UniswapKit.Kit
    private let swapTokenFactory: SwapTokenFactory
    private let swapTradeDataFactory: SwapTradeDataFactory

    private var swapData: SwapData? {
        didSet {
            syncTradeData()
        }
    }

    private var uniswapTradeData: TradeData? {
        didSet {
            tradeDataRelay.accept(tradeData)
        }
    }

    var tradeData: SwapTradeData? { uniswapTradeData.map { swapTradeDataFactory.swapTradeData(tradeData: $0) } }
    private let tradeDataRelay = PublishRelay<SwapTradeData?>()

    var amount: Decimal? {
        didSet {
            if oldValue != amount {
                syncTradeData()
            }
        }
    }

    var exactIn: Bool = true {
        didSet {
            exactInRelay.accept(exactIn)
            if oldValue != exactIn {
                syncSwapData()
            }
        }
    }
    private var exactInRelay = PublishRelay<Bool>()

    var tokenIn: SwapToken? {
        didSet {
            if oldValue != tokenIn {
                syncSwapData()
            }
        }
    }

    var tokenOut: SwapToken? {
        didSet {
            if oldValue != tokenOut {
                syncSwapData()
            }
        }
    }

    init(uniswapKit: UniswapKit.Kit, swapTokenFactory: SwapTokenFactory, swapTradeDataFactory: SwapTradeDataFactory) {
        self.uniswapKit = uniswapKit
        self.swapTokenFactory = swapTokenFactory
        self.swapTradeDataFactory = swapTradeDataFactory
    }

    private func syncSwapData() {
        guard let tokenIn = tokenIn, let tokenOut = tokenOut else {
            swapData = nil
            uniswapTradeData = nil
            return
        }
        uniswapKit.swapDataSingle(tokenIn: swapTokenFactory.uniswapToken(swapToken: tokenIn), tokenOut: swapTokenFactory.uniswapToken(swapToken: tokenOut))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] swapData in
                    print("SwapData:\n\(swapData)")

                    self?.swapData = swapData
                }, onError: { error in
                    print("SWAP DATA ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func syncTradeData() {
        guard let swapData = swapData, let amount = amount else {
            uniswapTradeData = nil
            return
        }

        if exactIn {
            uniswapTradeData = try? uniswapKit.bestTradeExactIn(swapData: swapData, amountIn: amount)
        } else {
            uniswapTradeData = try? uniswapKit.bestTradeExactOut(swapData: swapData, amountOut: amount)
        }
    }

}

extension UniswapService: ISwapAdapter {

    var routerAddress: Address {
        uniswapKit.routerAddress
    }

    func swapToken(token: Erc20Token?) -> SwapToken {
        let uniswapToken: UniswapKit.Token
        if let token = token {
            uniswapToken = uniswapKit.token(contractAddress: token.contractAddress, decimals: token.decimal)
        } else {
            uniswapToken = uniswapKit.etherToken
        }

        return swapTokenFactory.swapToken(uniswapToken: uniswapToken)
    }

    func transactionData() -> Single<TransactionData> {
        guard let uniswapTradeData = uniswapTradeData else {
            return Single.error(SwapError.noTradeData)
        }
        do {
            return try Single.just(uniswapKit.transactionData(tradeData: uniswapTradeData))
        } catch {
            return Single.error(error)
        }

    }

    var tradeDataObservable: Observable<SwapTradeData?> {
        tradeDataRelay.asObservable()
    }

}

extension UniswapService: IInputFieldSwapAdapter {

    var exactInObservable: Observable<Bool> {
        exactInRelay.asObservable()
    }

}

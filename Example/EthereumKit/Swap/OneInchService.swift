import EthereumKit
import OneInchKit
import RxSwift
import RxCocoa
import BigInt

class OneInchService {
    private var disposeBag = DisposeBag()
    private let oneInchKit: OneInchKit.Kit
    private let swapTokenFactory: SwapTokenFactory
    private let swapTradeDataFactory: SwapTradeDataFactory

    private var quote: OneInchKit.Quote? {
        didSet {
            tradeDataRelay.accept(tradeData)
        }
    }

    var tradeData: SwapTradeData? { quote.map { swapTradeDataFactory.swapTradeData(quote: $0) } }
    private let tradeDataRelay = PublishRelay<SwapTradeData?>()

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

    var amount: Decimal? {
        didSet {
            if oldValue != amount {
                syncSwapData()
            }
        }
    }

    init(oneInchKit: OneInchKit.Kit, swapTokenFactory: SwapTokenFactory, swapTradeDataFactory: SwapTradeDataFactory) {
        self.oneInchKit = oneInchKit
        self.swapTokenFactory = swapTokenFactory
        self.swapTradeDataFactory = swapTradeDataFactory
    }

    private func units(amount: Decimal, token: SwapToken) -> BigUInt? {
        let amountUnitString = (amount * pow(10, token.decimals)).roundedString(decimal: 0)
        return BigUInt(amountUnitString)
    }

    private func syncSwapData() {
        guard let tokenIn = tokenIn,
              let tokenOut = tokenOut,
              let amount = amount,
              let amountUnits = units(amount: amount, token: tokenIn) else {

            quote = nil
            return
        }

        disposeBag = DisposeBag()

        oneInchKit.quoteSingle(fromToken: tokenIn.address,
                toToken: tokenOut.address,
                amount: amountUnits,
                protocols: nil,
                gasPrice: nil,
                complexityLevel: nil,
                connectorTokens: nil,
                gasLimit: nil,
                mainRouteParts: nil,
                parts: nil)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] quote in
                    print("quote:\n\(quote)")

                    self?.quote = quote
                }, onError: { error in
                    print("Quote DATA ERROR: \(error)")
                })
                .disposed(by: disposeBag)

    }

}

extension OneInchService: ISwapAdapter {

    public var routerAddress: EthereumKit.Address {
        oneInchKit.routerAddress
    }

    public func swapToken(token: Erc20Token?) -> SwapToken {
        if let token = token {
            return .erc20(address: token.contractAddress, decimals: token.decimal)
        } else {
            return .eth(wethAddress: try! Address(hex: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"))
        }
    }

    public func transactionData() -> Single<TransactionData> {
        guard let tokenIn = tokenIn,
              let tokenOut = tokenOut,
              let amount = amount,
              let amountUnits = units(amount: amount, token: tokenIn),
              let _ = tradeData else {

            return Single.error(SwapError.noTradeData)
        }

        return oneInchKit.swapSingle(fromToken: tokenIn.address,
                toToken: tokenOut.address,
                amount: amountUnits,
                slippage: 0,
                protocols: nil,
                recipient: nil,
                gasPrice: nil,
                burnChi: nil,
                complexityLevel: nil,
                connectorTokens: nil,
                allowPartialFill: nil,
                gasLimit: nil,
                mainRouteParts: nil,
                parts: nil).map { (swap: Swap) -> EthereumKit.TransactionData in
                    EthereumKit.TransactionData(to: tokenOut.address, value: swap.transaction.value, input: swap.transaction.data)
                }

    }

    public var tradeDataObservable: Observable<SwapTradeData?> {
        tradeDataRelay.asObservable()
    }

}

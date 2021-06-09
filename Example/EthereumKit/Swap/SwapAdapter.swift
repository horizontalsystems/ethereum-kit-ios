import Foundation
import Foundation
import EthereumKit
import UniswapKit
import RxSwift

public protocol ISwapAdapter: AnyObject {

    var routerAddress: Address { get }

    var tokenIn: SwapToken? { get set }
    var tokenOut: SwapToken? { get set }
    var amount: Decimal? { get set }

    func swapToken(token: Erc20Token?) -> SwapToken
    func transactionData() -> Single<TransactionData>

    var tradeData: SwapTradeData? { get }
    var tradeDataObservable: Observable<SwapTradeData?> { get }
}

protocol IInputFieldSwapAdapter: AnyObject {

    var exactIn: Bool { get set }
    var exactInObservable: Observable<Bool> { get }

}

enum SwapError: Error {
    case noTradeData
}

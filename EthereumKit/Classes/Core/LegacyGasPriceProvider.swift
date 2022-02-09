import RxSwift

public class LegacyGasPriceProvider {
    private let evmKit: Kit

    public init(evmKit: Kit) {
        self.evmKit = evmKit
    }

    public func gasPriceSingle() -> Single<Int> {
        evmKit.rpcSingle(rpcRequest: GasPriceJsonRpc())
    }

}

import RxSwift

public class EIP1559GasPriceProvider {
    public enum FeeHistoryError: Error {
        case notAvailable
    }

    private let evmKit: Kit

    public init(evmKit: Kit) {
        self.evmKit = evmKit
    }

    public func feeHistoryObservable(blocksCount: Int, defaultBlockParameter: DefaultBlockParameter = .latest, rewardPercentile: [Int]) -> Observable<FeeHistory> {
        evmKit.lastBlockHeightObservable.flatMap { [weak self] _ -> Single<FeeHistory> in
            guard let provider = self else {
                return Single.error(FeeHistoryError.notAvailable)
            }

            return provider.feeHistorySingle(blocksCount: blocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: rewardPercentile)
        }
    }

    public func feeHistorySingle(blocksCount: Int, defaultBlockParameter: DefaultBlockParameter = .latest, rewardPercentile: [Int]) -> Single<FeeHistory> {
        let feeHistoryRequest = FeeHistoryJsonRpc(blocksCount: blocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: rewardPercentile)

        return evmKit.rpcSingle(rpcRequest: feeHistoryRequest)
    }

}

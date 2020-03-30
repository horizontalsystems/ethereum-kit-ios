import RxSwift

class EtherscanTransactionProvider {

    init() {
    }

}

extension EtherscanTransactionProvider: ITransactionProvider {

    func transactions(contractAddress: Data, address: Data, from: Int, to: Int) -> Single<[Transaction]> {
        Single.just([])
    }

}

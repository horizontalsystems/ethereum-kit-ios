import RxSwift

class ApiProvider {
}

extension ApiProvider: IApiProvider {

    func lastBlockHeightSingle() -> Single<Int> {
        fatalError("lastBlockHeightSingle() has not been implemented")
    }

    func transactionCountSingle(address: String) -> Single<Int> {
        fatalError("transactionCountSingle(address:) has not been implemented")
    }

    func balanceSingle(address: String) -> Single<String> {
        fatalError("balanceSingle(address:) has not been implemented")
    }

    func balanceErc20Single(address: String, contractAddress: String) -> Single<String> {
        fatalError("balanceErc20Single(address:contractAddress:) has not been implemented")
    }

    func transactionsSingle(address: String, startBlock: Int64) -> Single<[EthereumTransaction]> {
        fatalError("transactionsSingle(address:startBlock:) has not been implemented")
    }

    func transactionsErc20Single(address: String, startBlock: Int64) -> Single<[EthereumTransaction]> {
        fatalError("transactionsErc20Single(address:startBlock:) has not been implemented")
    }

    func sendSingle(signedTransactionHex: String) -> Single<Void> {
        fatalError("sendSingle(signedTransactionHex:) has not been implemented")
    }

}

import EthereumKit
import RxSwift
import BigInt

class DataProvider {
    private let ethereumKit: EthereumKit.Kit

    init(ethereumKit: EthereumKit.Kit) {
        self.ethereumKit = ethereumKit
    }

}

extension DataProvider: IDataProvider {

    var lastBlockHeight: Int {
        ethereumKit.lastBlockHeight ?? 0
    }

    func getTransactionStatuses(transactionHashes: [Data]) -> Single<[(Data, TransactionStatus)]> {
        let singles = transactionHashes.map { hash in
            ethereumKit.transactionStatus(transactionHash: hash).map { status -> (Data, TransactionStatus) in (hash, status) }
        }
        return Single.zip(singles)
    }

    func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt> {
        ethereumKit.call(contractAddress: contractAddress, data: BalanceOfMethod(owner: address).encodedABI())
                .flatMap { data -> Single<BigUInt> in
                    guard let value = BigUInt(data.hex, radix: 16) else {
                        return Single.error(Erc20Kit.TokenError.invalidHex)
                    }

                    return Single.just(value)
                }
    }

    func sendSingle(contractAddress: Address, transactionInput: Data, gasPrice: Int, gasLimit: Int) -> Single<Data> {
        ethereumKit.sendSingle(address: contractAddress, value: 0, transactionInput: transactionInput, gasPrice: gasPrice, gasLimit: gasLimit)
                .map { FullTransaction in
                    FullTransaction.transaction.hash
                }
    }

}

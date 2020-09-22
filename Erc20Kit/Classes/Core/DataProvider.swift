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

    func getTransactionLogs(contractAddress: Address, address: Address, from: Int, to: Int) -> Single<[EthereumLog]> {
        let addressTopic = Data(repeating: 0, count: 12) + address.raw
        let transferTopic = ContractEvent(name: "Transfer", arguments: [.address, .address, .uint256]).signature

        let topics: [[Any?]] = [
            [transferTopic, addressTopic],
            [transferTopic, nil, addressTopic]
        ]

        let singles = topics.map {
            ethereumKit.getLogsSingle(address: contractAddress, topics: $0, fromBlock: from, toBlock: to, pullTimestamps: true)
        }

        return Single.zip(singles) { logsArray -> [EthereumLog] in
                    Array(Set<EthereumLog>(logsArray.joined()))
                }
                .map { logs -> [EthereumLog] in
                    logs.filter { log in
                        log.topics.count == 3 &&
                                log.topics[0] == transferTopic &&
                                log.topics[1].count == 32 && log.topics[2].count == 32
                    }
                }
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
                .map { transactionWithInternal in
                    transactionWithInternal.transaction.hash
                }
    }

}

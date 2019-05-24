import EthereumKit
import RxSwift
import BigInt

class DataProvider {
    private let ethereumKit: EthereumKit

    init(ethereumKit: EthereumKit) {
        self.ethereumKit = ethereumKit
    }

}

extension DataProvider: IDataProvider {

    var lastBlockHeight: Int {
        return ethereumKit.lastBlockHeight ?? 0
    }

    func getTransactionLogs(contractAddress: Data, address: Data, from: Int, to: Int) -> Single<[EthereumLog]> {
        let addressTopic = Data(repeating: 0, count: 12) + address
        let transferTopic = ERC20.ContractLogs.transfer.topic

        let topics: [[Any?]] = [
            [transferTopic, addressTopic],
            [transferTopic, nil, addressTopic]
        ]

        let singles = topics.map {
            ethereumKit.getLogsSingle(address: contractAddress, topics: $0, fromBlock: from, toBlock: to, pullTimestamps: true)
        }

        return Single.zip(singles) { logsArray -> [EthereumLog] in
                    return Array(Set<EthereumLog>(logsArray.joined()))
                }
                .map { logs -> [EthereumLog] in
                    return logs.filter { log in
                        return log.topics.count == 3 &&
                              log.topics[0] == ERC20.ContractLogs.transfer.topic &&
                              log.topics[1].count == 32 && log.topics[2].count == 32
                        }
                    }
    }

    func getBalance(contractAddress: Data, address: Data) -> Single<BigUInt> {
        let balanceOfData = ERC20.ContractFunctions.balanceOf(address: address).data

        return ethereumKit.call(contractAddress: contractAddress, data: balanceOfData)
                .flatMap { data -> Single<BigUInt> in
                    guard let value = BigUInt(data.toRawHexString(), radix: 16) else {
                        return Single.error(Erc20Kit.TokenError.invalidAddress)
                    }

                    return Single.just(value)
                }
    }

    func sendSingle(contractAddress: Data, transactionInput: Data, gasPrice: Int, gasLimit: Int) -> Single<Data> {
        return ethereumKit.sendSingle(to: contractAddress, value: "0", transactionInput: transactionInput, gasPrice: gasPrice, gasLimit: gasLimit)
                .map { transactionInfo in
                    Data(hex: transactionInfo.hash)!
                }
    }

}

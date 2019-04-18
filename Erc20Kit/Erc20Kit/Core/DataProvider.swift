import EthereumKit
import HSCryptoKit
import RxSwift

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

    func getTransactions(from: Int, to: Int, address: Data) -> Single<[Transaction]> {
        let addressTopic = Data(repeating: 0, count: 12) + address

        let outgoingTopics = [Transaction.transferEventTopic, addressTopic]
        let incomingTopics = [Transaction.transferEventTopic, nil, addressTopic]

        let singles = [incomingTopics, outgoingTopics].map {
            ethereumKit.getLogsSingle(address: nil, topics: $0 as [Any], fromBlock: from, toBlock: to, pullTimestamps: true)
        }

        return Single.zip(singles) { logsArray -> [EthereumLog] in
                    return Array(Set<EthereumLog>(logsArray.joined()))
                }
                .map { logs -> [Transaction] in
                    return logs.compactMap { Transaction(log: $0) }
                }
    }

    func getStorageValue(contractAddress: Data, position: Int, address: Data, blockHeight: Int) -> Single<BInt> {
        var positionKeyData = Data(repeating: 0, count: 12) + address
        positionKeyData += Data(repeating: 0, count: 24) + Data(withUnsafeBytes(of: position) { Data($0) }).reversed()

        let positionData = CryptoKit.sha3(positionKeyData)

        return ethereumKit.getStorageAt(contractAddress: contractAddress, positionData: positionData, blockHeight: blockHeight)
                .flatMap { data -> Single<BInt> in
                    guard let value = BInt(data.toHexString(), radix: 16) else {
                        return Single.error(Erc20Kit.TokenError.invalidAddress)
                    }

                    return Single.just(value)
                }
    }

    func sendSingle(contractAddress: Data, transactionInput: Data, gasPrice: Int) -> Single<Data> {
        return ethereumKit.sendSingle(to: contractAddress, value: "0", transactionInput: transactionInput, gasPrice: gasPrice)
                .map { transactionInfo in
                    Data(hex: transactionInfo.hash)!
                }
    }

}

import HSEthereumKit

class DataProvider {

    private let ethereumKit: EthereumKit
    private let addressTopic: Data

    init(ethereumKit: EthereumKit, addressTopic: Data) {
        self.ethereumKit = ethereumKit
        self.addressTopic = addressTopic
    }

}

extension DataProvider: IDataProvider {

    func getLogs(from: Int, to: Int, completionFunction: @escaping ([Transaction], Int) -> ()) {
        let topics = [
            [Erc20Kit.transferEventTopic, addressTopic],
            [Erc20Kit.transferEventTopic, nil, addressTopic]
        ]

        ethereumKit.getLogs(address: nil, topics: topics, fromBlock: from, toBlock: to, pullTimestamps: false) { logs in
            let transactions = logs.compactMap {
                Transaction(log: $0)
            }

            completionFunction(transactions, to)
        }
    }

    func getStorageAt(for token: Token, toBlock: Int, completeFunction: @escaping (Token, BInt, Int) -> ()) {
        ethereumKit.getStorageAt(contractAddress: token.contractAddress, position: token.contractBalanceKey, blockNumber: toBlock) { blockNumber, balanceValue in
            guard let newValue = BInt(balanceValue.toHexString(), radix: 16) else {
                return
            }

            completeFunction(token, newValue, blockNumber)
        }
    }

}

import RxSwift
import BigInt
import EthereumKit

class EtherscanTransactionProvider {
    private let provider: EtherscanApiProvider

    init(provider: EtherscanApiProvider) {
        self.provider = provider
    }

}

extension EtherscanTransactionProvider: ITransactionProvider {

    func transactions(contractAddress: Data, address: Data, from: Int, to: Int) -> Single<[Transaction]> {
        provider.tokenTransactionsSingle(contractAddress: contractAddress, startBlock: from).map { array -> [Transaction] in
            var transactionIndexMap = [Data: Int]()

            return array.compactMap { data -> Transaction? in
                guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let from = data["from"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let to = data["to"].flatMap({ Data(hex: $0) }) else { return nil }
                guard let value = data["value"].flatMap({ BigUInt($0) }) else { return nil }
                guard let timestamp = data["timeStamp"].flatMap({ Double($0) }) else { return nil }

                let interTransactionIndex = transactionIndexMap[hash].map { $0 + 1 } ?? 0
                transactionIndexMap[hash] = interTransactionIndex

                let transaction = Transaction(
                        transactionHash: hash,
                        transactionIndex: data["transactionIndex"].flatMap { Int($0) },
                        from: from,
                        to: to,
                        value: value,
                        timestamp: timestamp,
                        interTransactionIndex: interTransactionIndex
                )

                transaction.blockHash = data["blockHash"].flatMap({ Data(hex: $0) })
                transaction.blockNumber = data["blockNumber"].flatMap { Int($0) }

                return transaction
            }
        }
    }

}

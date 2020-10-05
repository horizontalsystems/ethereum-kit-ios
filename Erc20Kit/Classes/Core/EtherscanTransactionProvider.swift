import RxSwift
import BigInt
import EthereumKit

class EtherscanTransactionProvider {
    private let provider: EtherscanApiProvider
    private let erc20SmartContract = Erc20Contract()

    init(provider: EtherscanApiProvider) {
        self.provider = provider
    }

    private func ethereumTransactions(address: Address, contractAddress: Address, startBlock: Int) -> Single<[EthereumKit.Transaction]> {
        provider.transactionsSingle(startBlock: startBlock)
                .map { dictionaries -> [EthereumKit.Transaction] in
                    dictionaries.compactMap { tx in
                        guard let toAddressHex = tx["to"],
                              toAddressHex == contractAddress.hex else {
                            return nil
                        }
                        guard let hashString = tx["hash"],
                              let hash = Data(hex: hashString),
                              let nonce = tx["nonce"].flatMap({ Int($0)}),
                              let inputString = tx["input"],
                              let input = Data(hex: inputString),
                              let fromAddressHex = tx["from"],
                              let from = try? Address(hex: fromAddressHex),
                              let to = try? Address(hex: toAddressHex),
                              let valueString = tx["value"],
                              let value = BigUInt(valueString, radix: 16),
                              let gasLimit = tx["gas"].flatMap({ Int($0)}),
                              let gasPrice = tx["gasPrice"].flatMap({ Int($0)}),
                              let timestamp = tx["timeStamp"].flatMap({ TimeInterval($0)}) else {
                            return nil
                        }

                        let ethTx = EthereumKit.Transaction(hash: hash, nonce: nonce, input: input, from: from, to: to, value: value, gasLimit: gasLimit, gasPrice: gasPrice, timestamp: timestamp)
                        ethTx.blockHash = tx["blockHash"].flatMap { Data(hex: $0) }
                        ethTx.blockNumber = tx["blockNumber"].flatMap({ Int($0)})
                        ethTx.gasUsed = tx["gasUsed"].flatMap({ Int($0)})
                        ethTx.cumulativeGasUsed = tx["cumulativeGasUsed"].flatMap({ Int($0)})
                        ethTx.isError = tx["isError"].flatMap({ Int($0)})
                        ethTx.transactionIndex = tx["transactionIndex"].flatMap({ Int($0)})
                        ethTx.txReceiptStatus = tx["txreceipt_status"].flatMap({ Int($0)})
                        
                        return ethTx
                    }
                }
    }

}

extension EtherscanTransactionProvider: ITransactionProvider {

    func transactions(contractAddress: Address, address: Address, from: Int, to: Int) -> Single<[Transaction]> {
        let fromInput = ethereumTransactions(address: address, contractAddress: contractAddress, startBlock: from)
            .map { [weak self] ethTxs in
                    ethTxs.reduce([]) { (result, ethTx) -> [Erc20Kit.Transaction] in
                        var result = result
                        if let new = self?.erc20SmartContract.getErc20TransactionsFromEthTransaction(ethTx: ethTx) {
                            result.append(contentsOf: new)
                        }
                        
                        return result
                    }
                }

        let transfers = provider.tokenTransactionsSingle(contractAddress: contractAddress, startBlock: from)
            .map { array -> [Transaction] in
                var transactionIndexMap = [Data: Int]()

                return array.compactMap { data -> Transaction? in
                    guard let hash = data["hash"].flatMap({ Data(hex: $0) }) else { return nil }
                    guard let from = data["from"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
                    guard let to = data["to"].flatMap({ Data(hex: $0) }).map({ Address(raw: $0) }) else { return nil }
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

        return Single.zip(fromInput, transfers)
            .map { t1, t2 in
                (t1 + t2).sorted { t1, t2 -> Bool in t1.timestamp > t2.timestamp }
            }
    }

}

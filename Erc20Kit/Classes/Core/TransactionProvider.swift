//import RxSwift
//import BigInt
//import EthereumKit
//
//class TransactionProvider {
//    private let dataProvider: IDataProvider
//
//    init(dataProvider: IDataProvider) {
//        self.dataProvider = dataProvider
//    }
//
//    private func transaction(log: EthereumLog) -> Transaction {
//        let value = BigUInt(log.data.hex, radix: 16)!
//        let from = Address(raw: log.topics[1].suffix(from: 12))
//        let to = Address(raw: log.topics[2].suffix(from: 12))
//
//        let transaction = Transaction(
//                transactionHash: log.transactionHash,
//                transactionIndex: log.transactionIndex,
//                from: from,
//                to: to,
//                value: value,
//                timestamp: log.timestamp ?? Date().timeIntervalSince1970,
//                interTransactionIndex: log.logIndex
//        )
//
//        transaction.logIndex = log.logIndex
//        transaction.blockHash = log.blockHash
//        transaction.blockNumber = log.blockNumber
//
//        return transaction
//    }
//
//}
//
//extension TransactionProvider: ITransactionProvider {
//
//    func transactions(contractAddress: Address, address: Address, from: Int, to: Int) -> Single<[Transaction]> {
//        dataProvider.getTransactionLogs(contractAddress: contractAddress, address: address, from: from, to: to)
//                .map { [weak self] logs in
//                    logs.compactMap { log in self?.transaction(log: log) }
//                }
//    }
//
//}

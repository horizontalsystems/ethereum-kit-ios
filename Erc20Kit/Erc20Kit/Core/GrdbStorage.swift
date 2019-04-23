import RxSwift
import EthereumKit
import GRDB

class GrdbStorage {
    internal let dbPool: DatabasePool

    init(databaseFileName: String) {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("\(databaseFileName).sqlite")

        let configuration: Configuration = Configuration()
//        configuration.trace = { print($0) }

        dbPool = try! DatabasePool(path: databaseURL.path, configuration: configuration)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createTokenBalances") { db in
            try db.create(table: TokenBalance.databaseTableName) { t in
                t.column(TokenBalance.Columns.contractAddress.name, .text).notNull()
                t.column(TokenBalance.Columns.value.name, .text).notNull()
                t.column(TokenBalance.Columns.blockHeight.name, .integer).notNull()

                t.primaryKey([TokenBalance.Columns.contractAddress.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactions") { db in
            try db.create(table: Transaction.databaseTableName) { t in
                t.column(Transaction.Columns.transactionHash.name, .text).notNull()
                t.column(Transaction.Columns.contractAddress.name, .text).notNull()
                t.column(Transaction.Columns.from.name, .text).notNull()
                t.column(Transaction.Columns.to.name, .text).notNull()
                t.column(Transaction.Columns.value.name, .text).notNull()
                t.column(Transaction.Columns.timestamp.name, .double)
                t.column(Transaction.Columns.logIndex.name, .integer)
                t.column(Transaction.Columns.blockHash.name, .text)
                t.column(Transaction.Columns.blockNumber.name, .integer)

                t.primaryKey([Transaction.Columns.transactionHash.name, Transaction.Columns.logIndex.name], onConflict: .replace)
            }
        }

        return migrator
    }
}

extension GrdbStorage: ITokenBalanceStorage {

    func tokenBalance(contractAddress: Data) -> TokenBalance? {
        return try! dbPool.read { db in
            try TokenBalance.filter(TokenBalance.Columns.contractAddress == contractAddress).fetchOne(db)
        }
    }

    func save(tokenBalance: TokenBalance) {
        _ = try? dbPool.write { db in
            try tokenBalance.insert(db)
        }
    }

    func clearTokenBalances() {
        _ = try? dbPool.write { db in
            try TokenBalance.deleteAll(db)
        }
    }

}

extension GrdbStorage: ITransactionStorage {

    var lastTransactionBlockHeight: Int? {
        return try! dbPool.read { db in
            try Transaction.order(Transaction.Columns.blockNumber.desc).fetchOne(db)?.blockNumber
        }
    }

    func lastTransactionBlockHeight(contractAddress: Data) -> Int? {
        return try! dbPool.read { db in
            try Transaction.filter(Transaction.Columns.contractAddress == contractAddress).order(Transaction.Columns.blockNumber.desc).fetchOne(db)?.blockNumber
        }
    }

    func transactionsCount(contractAddress: Data) -> Int {
        return try! dbPool.read { db in
            try Transaction.filter(Transaction.Columns.contractAddress == contractAddress).fetchCount(db)
        }
    }

    func transactionsSingle(contractAddress: Data, from: (hash: Data, index: Int)?, limit: Int?) -> Single<[Transaction]> {
        return Single.create { [weak self] observer in
            try? self?.dbPool.read { db in
                var request = Transaction.filter(Transaction.Columns.contractAddress == contractAddress)

                if let from = from,
                   let fromTransaction = try request.filter(Transaction.Columns.transactionHash == from.hash).filter(Transaction.Columns.logIndex == from.index).fetchOne(db) {
                    request = request.filter(Transaction.Columns.timestamp < fromTransaction.timestamp || (Transaction.Columns.timestamp == fromTransaction.timestamp && Transaction.Columns.logIndex < from.index))
                }
                if let limit = limit {
                    request = request.limit(limit)
                }

                let transactions = try request.order(Transaction.Columns.timestamp.desc, Transaction.Columns.logIndex.desc).fetchAll(db)

                observer(.success(transactions))
            }

            return Disposables.create()
        }
    }

    func save(transactions: [Transaction]) {
        _ = try? dbPool.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }

    func update(transaction: Transaction) {
        _ = try? dbPool.write { db in
            try transaction.update(db)
        }
    }

    func clearTransactions() {
        _ = try? dbPool.write { db in
            try Transaction.deleteAll(db)
        }
    }

}

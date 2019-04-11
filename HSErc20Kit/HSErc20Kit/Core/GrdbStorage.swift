import RxSwift
import HSEthereumKit
import GRDB

class GrdbStorage {
    internal let dbPool: DatabasePool

    init(databaseFileName: String) {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("\(databaseFileName).sqlite")

        var configuration: Configuration = Configuration()
        configuration.trace = { print($0) }

        dbPool = try! DatabasePool(path: databaseURL.path, configuration: configuration)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

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

        migrator.registerMigration("createTokens") { db in
            try db.create(table: Token.databaseTableName) { t in
                t.column(Token.Columns.contractAddress.name, .text).notNull()
                t.column(Token.Columns.contractBalanceKey.name, .text).notNull()
                t.column(Token.Columns.balance.name, .text).notNull()
                t.column(Token.Columns.syncedBlockHeight.name, .integer).notNull()

                t.primaryKey([Token.Columns.contractAddress.name], onConflict: .replace)
            }
        }

        return migrator
    }
}

extension GrdbStorage {

    // Token

    func token(contractAddress: Data) -> Token? {
        return try! dbPool.read { db in
            try Token.filter(Token.Columns.contractAddress == contractAddress).fetchOne(db)
        }
    }

    func save(token: Token) {
        _ = try? dbPool.write { db in
            try token.save(db)
        }
    }

    // Transactions

    func transactionsSingle(contractAddress: Data, hashFrom: Data?, indexFrom: Int?, limit: Int?) -> Single<[Transaction]> {
        return Single.create { [weak self] observer in
            try? self?.dbPool.read { db in
                var request = Transaction.filter(Transaction.Columns.contractAddress == contractAddress)

                if let hashFrom = hashFrom, let indexFrom = indexFrom,
                   let fromTransaction = try request.filter(Transaction.Columns.transactionHash == hashFrom).filter(Transaction.Columns.logIndex == indexFrom).fetchOne(db) {
                    request = request.filter(Transaction.Columns.timestamp < fromTransaction.timestamp)
                }
                if let limit = limit {
                    request = request.limit(limit)
                }

                let transactions = try request.order(Transaction.Columns.timestamp.desc).fetchAll(db)

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

    func lastTransactionBlockHeight() -> Int? {
        return try! dbPool.read { db in
            try Transaction.order(Transaction.Columns.blockNumber.desc).fetchOne(db)?.blockNumber
        }
    }

    func clear() {
        _ = try? dbPool.write { db in
            try Transaction.deleteAll(db)
            try Token.deleteAll(db)
        }

    }

}

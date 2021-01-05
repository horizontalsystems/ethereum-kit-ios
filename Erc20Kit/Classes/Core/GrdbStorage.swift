import RxSwift
import BigInt
import GRDB

class GrdbStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        let configuration: Configuration = Configuration()
//        configuration.trace = { print($0) }

        dbPool = try! DatabasePool(path: databaseURL.path, configuration: configuration)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createTokenBalances") { db in
            try db.create(table: TokenBalance.databaseTableName) { t in
                t.column(TokenBalance.Columns.primaryKey.name, .text).notNull()
                t.column(TokenBalance.Columns.value.name, .text)

                t.primaryKey([TokenBalance.Columns.primaryKey.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactions") { db in
            try db.create(table: TransactionRecord.databaseTableName) { t in
                t.column(TransactionRecord.Columns.hash.name, .text).notNull()
//                t.column(TransactionRecord.Columns.transactionIndex.name, .integer)
                t.column(TransactionRecord.Columns.from.name, .text).notNull()
                t.column(TransactionRecord.Columns.to.name, .text).notNull()
                t.column(TransactionRecord.Columns.value.name, .text).notNull()
                t.column(TransactionRecord.Columns.timestamp.name, .double).notNull()
                t.column(TransactionRecord.Columns.interTransactionIndex.name, .integer).notNull()
                t.column(TransactionRecord.Columns.logIndex.name, .integer)
//                t.column(TransactionRecord.Columns.blockHash.name, .text)
//                t.column(TransactionRecord.Columns.blockNumber.name, .integer)

                t.primaryKey([TransactionRecord.Columns.hash.name, TransactionRecord.Columns.interTransactionIndex.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("addIsErrorToTransactions") { db in
            try db.alter(table: TransactionRecord.databaseTableName) { t in
//                t.add(column: TransactionRecord.Columns.isError.name, .blob).notNull().defaults(to: false)
            }
        }

        migrator.registerMigration("addTypeToTransactions") { db in
            try db.alter(table: TransactionRecord.databaseTableName) { t in
                t.add(column: TransactionRecord.Columns.type.name, .text).notNull().defaults(to: TransactionType.transfer.rawValue)
            }
        }

        migrator.registerMigration("recreateTransactions") { db in
            try db.drop(table: TransactionRecord.databaseTableName)

            try db.create(table: TransactionRecord.databaseTableName) { t in
                t.column(TransactionRecord.Columns.hash.name, .text).notNull()
                t.column(TransactionRecord.Columns.interTransactionIndex.name, .integer).notNull()
                t.column(TransactionRecord.Columns.logIndex.name, .integer)
                t.column(TransactionRecord.Columns.from.name, .text).notNull()
                t.column(TransactionRecord.Columns.to.name, .text).notNull()
                t.column(TransactionRecord.Columns.value.name, .text).notNull()
                t.column(TransactionRecord.Columns.timestamp.name, .integer).notNull()
                t.column(TransactionRecord.Columns.type.name, .text).notNull()

                t.primaryKey([TransactionRecord.Columns.hash.name, TransactionRecord.Columns.interTransactionIndex.name], onConflict: .replace)
            }
        }

        return migrator
    }
}

extension GrdbStorage: ITokenBalanceStorage {

    var balance: BigUInt? {
        get {
            let tokenBalance = try! dbPool.read { db in
                try TokenBalance.fetchOne(db)
            }
            return tokenBalance?.value
        }
        set {
            let tokenBalance = TokenBalance(value: newValue)

            _ = try! dbPool.write { db in
                try tokenBalance.insert(db)
            }
        }
    }

}

extension GrdbStorage: ITransactionStorage {

    var pendingTransactions: [TransactionRecord] {
        try! dbPool.read { db in
            try TransactionRecord.filter(TransactionRecord.Columns.logIndex == nil).fetchAll(db)
        }
    }

    var lastTransaction: TransactionRecord? {
        try? dbPool.read { db in
            try TransactionRecord.order(TransactionRecord.Columns.timestamp.desc, TransactionRecord.Columns.interTransactionIndex.desc).fetchOne(db)
        }
    }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        Single.create { [weak self] observer in
            try! self?.dbPool.read { db in
                var request = TransactionRecord.order(TransactionRecord.Columns.timestamp.desc, TransactionRecord.Columns.interTransactionIndex.desc)

                if let from = from, let fromTransaction = try request.filter(TransactionRecord.Columns.hash == from.hash).filter(TransactionRecord.Columns.interTransactionIndex == from.interTransactionIndex).fetchOne(db) {
                    let index = fromTransaction.interTransactionIndex
                    request = request.filter(
                            TransactionRecord.Columns.timestamp < fromTransaction.timestamp ||
                                    (TransactionRecord.Columns.timestamp == fromTransaction.timestamp && TransactionRecord.Columns.interTransactionIndex < index) ||
                                    (TransactionRecord.Columns.timestamp == fromTransaction.timestamp && TransactionRecord.Columns.interTransactionIndex == fromTransaction.interTransactionIndex && TransactionRecord.Columns.interTransactionIndex < from.interTransactionIndex)
                    )
                }
                if let limit = limit {
                    request = request.limit(limit)
                }

                observer(.success(try request.fetchAll(db)))
            }

            return Disposables.create()
        }
    }

    func save(transaction: TransactionRecord) {
        _ = try! dbPool.write { db in
            try transaction.insert(db)
        }
    }

}

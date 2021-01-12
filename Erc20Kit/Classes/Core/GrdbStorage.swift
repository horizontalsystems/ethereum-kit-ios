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
            try db.create(table: TransactionCache.databaseTableName) { t in
                t.column(TransactionCache.Columns.hash.name, .text).notNull()
//                t.column(TransactionRecord.Columns.transactionIndex.name, .integer)
                t.column(TransactionCache.Columns.from.name, .text).notNull()
                t.column(TransactionCache.Columns.to.name, .text).notNull()
                t.column(TransactionCache.Columns.value.name, .text).notNull()
                t.column(TransactionCache.Columns.timestamp.name, .double).notNull()
                t.column(TransactionCache.Columns.interTransactionIndex.name, .integer).notNull()
                t.column(TransactionCache.Columns.logIndex.name, .integer)
//                t.column(TransactionRecord.Columns.blockHash.name, .text)
//                t.column(TransactionRecord.Columns.blockNumber.name, .integer)

                t.primaryKey([TransactionCache.Columns.hash.name, TransactionCache.Columns.interTransactionIndex.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("addIsErrorToTransactions") { db in
            try db.alter(table: TransactionCache.databaseTableName) { t in
//                t.add(column: TransactionRecord.Columns.isError.name, .blob).notNull().defaults(to: false)
            }
        }

        migrator.registerMigration("addTypeToTransactions") { db in
            try db.alter(table: TransactionCache.databaseTableName) { t in
                t.add(column: TransactionCache.Columns.type.name, .text).notNull().defaults(to: TransactionType.transfer.rawValue)
            }
        }

        migrator.registerMigration("recreateTransactions") { db in
            try db.drop(table: TransactionCache.databaseTableName)

            try db.create(table: TransactionCache.databaseTableName) { t in
                t.column(TransactionCache.Columns.hash.name, .text).notNull()
                t.column(TransactionCache.Columns.interTransactionIndex.name, .integer).notNull()
                t.column(TransactionCache.Columns.logIndex.name, .integer)
                t.column(TransactionCache.Columns.from.name, .text).notNull()
                t.column(TransactionCache.Columns.to.name, .text).notNull()
                t.column(TransactionCache.Columns.value.name, .text).notNull()
                t.column(TransactionCache.Columns.timestamp.name, .integer).notNull()
                t.column(TransactionCache.Columns.type.name, .text).notNull()

                t.primaryKey([TransactionCache.Columns.hash.name, TransactionCache.Columns.interTransactionIndex.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactionSyncStates") { db in
            try db.create(table: TransactionSyncOrder.databaseTableName) { t in
                t.column(TransactionSyncOrder.Columns.primaryKey.name, .text).notNull()
                t.column(TransactionSyncOrder.Columns.value.name, .integer)

                t.primaryKey([TransactionSyncOrder.Columns.primaryKey.name], onConflict: .replace)
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

    var pendingTransactions: [TransactionCache] {
        try! dbPool.read { db in
            try TransactionCache.filter(TransactionCache.Columns.logIndex == nil).fetchAll(db)
        }
    }

    var lastSyncOrder: Int? {
        get {
            let transactionSyncOrder = try! dbPool.read { db in
                try TransactionSyncOrder.fetchOne(db)
            }
            return transactionSyncOrder?.value
        }
        set {
            let transactionSyncOrder = TransactionSyncOrder(value: newValue)

            _ = try! dbPool.write { db in
                try transactionSyncOrder.insert(db)
            }
        }
    }

    func transactionsSingle(from: (hash: Data, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionCache]> {
        Single.create { [weak self] observer in
            try! self?.dbPool.read { db in
                var request = TransactionCache.order(TransactionCache.Columns.timestamp.desc, TransactionCache.Columns.interTransactionIndex.desc)

                if let from = from, let fromTransaction = try request.filter(TransactionCache.Columns.hash == from.hash).filter(TransactionCache.Columns.interTransactionIndex == from.interTransactionIndex).fetchOne(db) {
                    let index = fromTransaction.interTransactionIndex
                    request = request.filter(
                            TransactionCache.Columns.timestamp < fromTransaction.timestamp ||
                                    (TransactionCache.Columns.timestamp == fromTransaction.timestamp && TransactionCache.Columns.interTransactionIndex < index) ||
                                    (TransactionCache.Columns.timestamp == fromTransaction.timestamp && TransactionCache.Columns.interTransactionIndex == fromTransaction.interTransactionIndex && TransactionCache.Columns.interTransactionIndex < from.interTransactionIndex)
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

    func save(transaction: TransactionCache) {
        _ = try! dbPool.write { db in
            try transaction.insert(db)
        }
    }

}

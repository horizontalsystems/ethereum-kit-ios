import RxSwift
import GRDB

class TransactionStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createTransactions") { db in
            try db.create(table: Transaction.databaseTableName) { t in
                t.column(Transaction.Columns.hash.name, .text).notNull()
                t.column(Transaction.Columns.nonce.name, .integer).notNull()
                t.column(Transaction.Columns.input.name, .text).notNull()
                t.column(Transaction.Columns.from.name, .text).notNull()
                t.column(Transaction.Columns.to.name, .text).notNull()
                t.column(Transaction.Columns.value.name, .text).notNull()
                t.column(Transaction.Columns.gasLimit.name, .integer).notNull()
                t.column(Transaction.Columns.gasPrice.name, .integer).notNull()
                t.column(Transaction.Columns.timestamp.name, .double).notNull()
                t.column(Transaction.Columns.blockHash.name, .text)
                t.column(Transaction.Columns.blockNumber.name, .integer)
                t.column(Transaction.Columns.gasUsed.name, .integer)
                t.column(Transaction.Columns.cumulativeGasUsed.name, .integer)
                t.column(Transaction.Columns.isError.name, .integer)
                t.column(Transaction.Columns.transactionIndex.name, .integer)
                t.column(Transaction.Columns.txReceiptStatus.name, .integer)

                t.primaryKey([Transaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createInternalTransactions") { db in
            try db.create(table: InternalTransaction.databaseTableName) { t in
                t.column(InternalTransaction.Columns.hash.name, .text)
                        .notNull()
                        .indexed()
                        .references(Transaction.databaseTableName, column: Transaction.Columns.hash.name, onDelete: .cascade)
                t.column(InternalTransaction.Columns.blockNumber.name, .integer).notNull()
                t.column(InternalTransaction.Columns.from.name, .text).notNull()
                t.column(InternalTransaction.Columns.to.name, .text).notNull()
                t.column(InternalTransaction.Columns.value.name, .text).notNull()
                t.column(InternalTransaction.Columns.traceId.name, .integer).notNull()

                t.primaryKey([InternalTransaction.Columns.hash.name, InternalTransaction.Columns.traceId.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension TransactionStorage: ITransactionStorage {

    var lastTransaction: Transaction? {
        try? dbPool.read { db in
            try Transaction.order(Transaction.Columns.blockNumber.desc).fetchOne(db)
        }
    }

    func transactionsSingle(fromHash: Data?, limit: Int?) -> Single<[TransactionWithInternal]> {
        Single.create { [weak self] observer in
            try? self?.dbPool.read { db in
                var request = Transaction
                        .including(all: Transaction.internalTransactions)
                        .having(Transaction.internalTransactions.isEmpty == false || Transaction.Columns.value > 0)

                if let fromHash = fromHash, let fromTransaction = try request.filter(Transaction.Columns.hash == fromHash).fetchOne(db) {
                    let transactionIndex = fromTransaction.transactionIndex ?? 0
                    request = request.filter(Transaction.Columns.timestamp < fromTransaction.timestamp || (Transaction.Columns.timestamp == fromTransaction.timestamp && Transaction.Columns.transactionIndex < transactionIndex))
                }

                if let limit = limit {
                    request = request.limit(limit)
                }

                request = request.order(Transaction.Columns.timestamp.desc, Transaction.Columns.transactionIndex.desc)

                let transactionsWithInternal = try TransactionWithInternal.fetchAll(db, request)

                observer(.success(transactionsWithInternal))
            }

            return Disposables.create()
        }
    }

    func transaction(hash: Data) -> TransactionWithInternal? {
        try? dbPool.read { db in
            let request = Transaction.including(all: Transaction.internalTransactions).filter(Transaction.Columns.hash == hash)
            return try TransactionWithInternal.fetchOne(db, request)
        }
    }

    func save(transactions: [Transaction]) {
        _ = try? dbPool.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }

}

extension TransactionStorage: IInternalTransactionStorage {

    var lastInternalTransactionBlockHeight: Int? {
        try! dbPool.read { db in
            try InternalTransaction.order(InternalTransaction.Columns.blockNumber.desc).fetchOne(db)?.blockNumber
        }
    }

    func save(internalTransactions: [InternalTransaction]) {
        _ = try? dbPool.write { db in
            for internalTransaction in internalTransactions {
                try internalTransaction.insert(db)
            }
        }
    }

}

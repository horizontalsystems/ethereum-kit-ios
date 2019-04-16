import RxSwift
import GRDB

class BaseGrdbStorage {
    internal let dbPool: DatabasePool

    init(databaseFileName: String) {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("\(databaseFileName).sqlite")

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

        return migrator
    }

}

extension BaseGrdbStorage {

    // Transactions

    func transactionsSingle(fromHash: Data?, limit: Int?, contractAddress: Data?) -> Single<[Transaction]> {
        return Single.create { [weak self] observer in
            try? self?.dbPool.read { db in
                var request = Transaction.all()

                if let contractAddress = contractAddress {
                    request = request.filter(Transaction.Columns.to == contractAddress)
                } else {
                    request = request.filter(Transaction.Columns.input == Data())
                }

                if let fromHash = fromHash, let fromTransaction = try request.filter(Transaction.Columns.hash == fromHash).fetchOne(db) {
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

}

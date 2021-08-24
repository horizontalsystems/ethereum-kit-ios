import RxSwift
import GRDB

class TransactionStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
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

        migrator.registerMigration("recreateTransactions") { db in
            try InternalTransaction.deleteAll(db)
            try db.drop(table: Transaction.databaseTableName)

            try db.create(table: Transaction.databaseTableName) { t in
                t.column(Transaction.Columns.hash.name, .text).notNull()
                t.column(Transaction.Columns.nonce.name, .integer).notNull()
                t.column(Transaction.Columns.input.name, .text).notNull()
                t.column(Transaction.Columns.from.name, .text).notNull()
                t.column(Transaction.Columns.to.name, .text).notNull()
                t.column(Transaction.Columns.value.name, .text).notNull()
                t.column(Transaction.Columns.gasLimit.name, .integer).notNull()
                t.column(Transaction.Columns.gasPrice.name, .integer).notNull()
                t.column(Transaction.Columns.timestamp.name, .integer).notNull()

                t.primaryKey([Transaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("recreateInternalTransactions") { db in
            try db.drop(table: InternalTransaction.databaseTableName)
            try db.create(table: InternalTransaction.databaseTableName) { t in
                t.column(InternalTransaction.Columns.hash.name, .text).notNull().indexed()
                t.column(InternalTransaction.Columns.blockNumber.name, .integer).notNull()
                t.column(InternalTransaction.Columns.from.name, .text).notNull()
                t.column(InternalTransaction.Columns.to.name, .text).notNull()
                t.column(InternalTransaction.Columns.value.name, .text).notNull()
                t.column(InternalTransaction.Columns.traceId.name, .integer).notNull()

                t.primaryKey([InternalTransaction.Columns.hash.name, InternalTransaction.Columns.traceId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactionReceipts") { db in
            try db.create(table: TransactionReceipt.databaseTableName) { t in
                t.column(TransactionReceipt.Columns.transactionHash.name, .text).notNull()
                t.column(TransactionReceipt.Columns.transactionIndex.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.blockHash.name, .text).notNull()
                t.column(TransactionReceipt.Columns.blockNumber.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.from.name, .text).notNull()
                t.column(TransactionReceipt.Columns.to.name, .text)
                t.column(TransactionReceipt.Columns.cumulativeGasUsed.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.gasUsed.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.contractAddress.name, .text)
                t.column(TransactionReceipt.Columns.logsBloom.name, .text).notNull()
                t.column(TransactionReceipt.Columns.root.name, .text)
                t.column(TransactionReceipt.Columns.status.name, .integer)

                t.primaryKey([TransactionReceipt.Columns.transactionHash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactionLogs") { db in
            try db.create(table: TransactionLog.databaseTableName) { t in
                t.column(TransactionLog.Columns.address.name, .text).notNull()
                t.column(TransactionLog.Columns.blockHash.name, .text).notNull()
                t.column(TransactionLog.Columns.blockNumber.name, .integer).notNull()
                t.column(TransactionLog.Columns.data.name, .text).notNull()
                t.column(TransactionLog.Columns.logIndex.name, .integer).notNull()
                t.column(TransactionLog.Columns.removed.name, .boolean).notNull()
                t.column(TransactionLog.Columns.topics.name, .text).notNull()
                t.column(TransactionLog.Columns.transactionHash.name, .text).notNull()
                t.column(TransactionLog.Columns.transactionIndex.name, .integer).notNull()

                t.primaryKey(
                        [TransactionLog.Columns.transactionHash.name, TransactionLog.Columns.logIndex.name],
                        onConflict: .replace
                )
                t.foreignKey(
                        [TransactionLog.Columns.transactionHash.name],
                        references: TransactionReceipt.databaseTableName,
                        columns: [TransactionReceipt.Columns.transactionHash.name],
                        onDelete: .cascade
                )
            }
        }

        migrator.registerMigration("createNotSyncedTransactions") { db in
            try db.create(table: NotSyncedTransaction.databaseTableName) { t in
                t.column(NotSyncedTransaction.Columns.hash.name, .text).notNull()
                t.column(NotSyncedTransaction.Columns.nonce.name, .integer)
                t.column(NotSyncedTransaction.Columns.from.name, .text)
                t.column(NotSyncedTransaction.Columns.to.name, .text)
                t.column(NotSyncedTransaction.Columns.value.name, .text)
                t.column(NotSyncedTransaction.Columns.gasPrice.name, .integer)
                t.column(NotSyncedTransaction.Columns.gasLimit.name, .integer)
                t.column(NotSyncedTransaction.Columns.input.name, .text)
                t.column(NotSyncedTransaction.Columns.blockHash.name, .text)
                t.column(NotSyncedTransaction.Columns.blockNumber.name, .integer)
                t.column(NotSyncedTransaction.Columns.transactionIndex.name, .integer)
                t.column(NotSyncedTransaction.Columns.timestamp.name, .integer)

                t.primaryKey([NotSyncedTransaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactionSyncerStates") { db in
            try db.create(table: TransactionSyncerState.databaseTableName) { t in
                t.column(TransactionSyncerState.Columns.id.name, .text).notNull().primaryKey()
                t.column(TransactionSyncerState.Columns.lastBlockNumber.name, .integer).notNull()
            }
        }

        migrator.registerMigration("addSyncOrderToTransactions") { db in
            try db.alter(table: Transaction.databaseTableName) { t in
                t.add(column: "syncOrder", .integer).notNull().indexed().defaults(to: 0)
            }
        }

        migrator.registerMigration("createDroppedTransactions") { db in
            try db.create(table: DroppedTransaction.databaseTableName) { t in
                t.column(DroppedTransaction.Columns.hash.name, .text).notNull().primaryKey()
                t.column(DroppedTransaction.Columns.replacedWith.name, .text).notNull()
            }
        }

        migrator.registerMigration("changeTraceIdInInternalTransactions") { db in
            let internalTransactions = try InternalTransaction.fetchAll(db)
            try db.drop(table: InternalTransaction.databaseTableName)
            try db.create(table: InternalTransaction.databaseTableName) { t in
                t.column(InternalTransaction.Columns.hash.name, .text).notNull().indexed()
                t.column(InternalTransaction.Columns.blockNumber.name, .integer).notNull()
                t.column(InternalTransaction.Columns.from.name, .text).notNull()
                t.column(InternalTransaction.Columns.to.name, .text).notNull()
                t.column(InternalTransaction.Columns.value.name, .text).notNull()
                t.column(InternalTransaction.Columns.traceId.name, .text).notNull()

                t.primaryKey([InternalTransaction.Columns.hash.name, InternalTransaction.Columns.traceId.name], onConflict: .replace)
            }

            for tx in internalTransactions {
                try tx.insert(db)
            }
        }

        migrator.registerMigration("createTransactionTags") { db in
            try db.create(table: TransactionTag.databaseTableName) { t in
                t.column(TransactionTag.Columns.name.name, .text).notNull().indexed()
                t.column(TransactionTag.Columns.transactionHash.name, .text).notNull()

                t.uniqueKey([TransactionTag.Columns.name.name, TransactionTag.Columns.transactionHash.name])
            }
        }

        migrator.registerMigration("createNotSyncedInternalTransactions") { db in
            try db.create(table: NotSyncedInternalTransaction.databaseTableName) { t in
                t.column(NotSyncedInternalTransaction.Columns.hash.name, .text).notNull()

                t.primaryKey([NotSyncedInternalTransaction.Columns.hash.name], onConflict: .ignore)
            }
        }

        migrator.registerMigration("dumpTransactions") { db in
            try Transaction.deleteAll(db)
            try TransactionLog.deleteAll(db)
            try TransactionReceipt.deleteAll(db)
            try InternalTransaction.deleteAll(db)
            try NotSyncedTransaction.deleteAll(db)
            try DroppedTransaction.deleteAll(db)
            try TransactionSyncerState.deleteAll(db)
        }

        migrator.registerMigration("addRetryCountToNotSyncedInternalTransactions") { db in
            try db.alter(table: NotSyncedInternalTransaction.databaseTableName) { t in
                t.add(column: NotSyncedInternalTransaction.Columns.retryCount.name, .integer).notNull().defaults(to: 0)
            }
        }

        migrator.registerMigration("addIndexOnTransactionHashToTransactionLog") { db in
            try db.create(index: "transaction_logs_transaction_hash", on: TransactionLog.databaseTableName, columns: [TransactionLog.Columns.transactionHash.name])
        }

        migrator.registerMigration("alterTransactionTagPrimaryKey") { db in
            let tmpTableName = "tmp_table"
            try db.rename(table: TransactionTag.databaseTableName, to: tmpTableName)

            for indexInfo in try db.indexes(on: tmpTableName) {
                if !indexInfo.isUnique {
                    try db.drop(index: indexInfo.name)
                }
            }

            try db.create(table: TransactionTag.databaseTableName) { t in
                t.column(TransactionTag.Columns.name.name, .text).notNull().indexed()
                t.column(TransactionTag.Columns.transactionHash.name, .text).notNull()

                t.uniqueKey([TransactionTag.Columns.name.name, TransactionTag.Columns.transactionHash.name], onConflict: .ignore)
            }

            for row in try Row.fetchAll(db, sql: "SELECT * FROM \(tmpTableName)") {
                try TransactionTag(row: row).insert(db)
            }

            try db.drop(table: tmpTableName)
        }

        return migrator
    }

    func fullTransactions(from transactions: [Transaction]) -> [FullTransaction] {
        let hashes = transactions.map { $0.hash }

        let receipts = try! dbPool.read { db -> [ReceiptWithLogs] in
            let request = TransactionReceipt
                    .including(all: TransactionReceipt.logs)
                    .filter(hashes.contains(TransactionReceipt.Columns.transactionHash))

            return try ReceiptWithLogs.fetchAll(db, request)
        }

        let internals = try! dbPool.read { db in
            try InternalTransaction
                    .filter(hashes.contains(InternalTransaction.Columns.hash))
                    .fetchAll(db)
        }

        let droppedTransactions = try! dbPool.read { db in
            try DroppedTransaction
                    .filter(hashes.contains(DroppedTransaction.Columns.hash))
                    .fetchAll(db)
        }

        let groupedReceipts = Dictionary(grouping: receipts, by: { $0.receipt.transactionHash })
        let groupedInternals = Dictionary(grouping: internals, by: { $0.hash })
        let groupedDroppedTransactions = Dictionary(grouping: droppedTransactions, by: { $0.hash })

        return transactions.map { transaction -> FullTransaction in
            FullTransaction(
                    transaction: transaction,
                    receiptWithLogs: groupedReceipts[transaction.hash]?.first,
                    internalTransactions: groupedInternals[transaction.hash] ?? [],
                    replacedWith: groupedDroppedTransactions[transaction.hash]?.first?.replacedWith
            )
        }
    }

}

extension TransactionStorage: ITransactionStorage {

    func notSyncedTransactions(limit: Int) -> [NotSyncedTransaction] {
        try! dbPool.read { db in
            try NotSyncedTransaction.limit(limit).fetchAll(db)
        }
    }

    func notSyncedInternalTransaction() -> NotSyncedInternalTransaction? {
        try! dbPool.read { db in
            try NotSyncedInternalTransaction.fetchOne(db)
        }
    }

    func add(notSyncedTransactions: [NotSyncedTransaction]) {
        try! dbPool.write { db in
            for transaction in notSyncedTransactions {
                try transaction.insert(db)
            }
        }
    }

    func save(notSyncedInternalTransaction: NotSyncedInternalTransaction) {
        try! dbPool.write { db in
            try notSyncedInternalTransaction.save(db)
        }
    }

    func update(notSyncedTransaction: NotSyncedTransaction) {
        try! dbPool.write { db in
            try notSyncedTransaction.update(db)
        }
    }

    func remove(notSyncedTransaction: NotSyncedTransaction) {
        _ = try! dbPool.write { db in
            try notSyncedTransaction.delete(db)
        }
    }

    func remove(notSyncedInternalTransaction: NotSyncedInternalTransaction) {
        _ = try! dbPool.write { db in
            try notSyncedInternalTransaction.delete(db)
        }
    }

    func save(transaction: Transaction) {
        try! dbPool.write { db in
            try transaction.save(db)
        }
    }

    func pendingTransactions(fromTransaction: Transaction?) -> [Transaction] {
        (try? dbPool.read { db in
            var whereClause = "transaction_receipts.transactionHash IS NULL AND dropped_transactions.hash IS NULL"
            if let transaction = fromTransaction {
                whereClause += " AND (transactions.nonce > \(transaction.nonce) OR (transactions.nonce = \(transaction.nonce) AND transactions.timestamp > \(transaction.timestamp)))"
            }

            return try Transaction
                    .joining(optional: Transaction.receipt)
                    .joining(optional: Transaction.droppedTransaction)
                    .filter(sql: whereClause)
                    .order(Transaction.Columns.nonce.asc, Transaction.Columns.timestamp.asc)
                    .fetchAll(db)
        }) ?? [Transaction]()
    }

    func pendingTransaction(nonce: Int) -> Transaction? {
        try? dbPool.read { db in
            try Transaction
                    .joining(optional: Transaction.receipt)
                    .joining(optional: Transaction.droppedTransaction)
                    .filter(sql: "transaction_receipts.transactionHash IS NULL AND dropped_transactions.hash IS NULL AND transactions.nonce = \(nonce)")
                    .order(Transaction.Columns.nonce.asc, Transaction.Columns.timestamp.asc)
                    .fetchOne(db)
        }
    }

    func save(transactionReceipt: TransactionReceipt) {
        try! dbPool.write { db in
            try transactionReceipt.insert(db)
        }
    }

    func transactionReceipt(hash: Data) -> TransactionReceipt? {
        try! dbPool.read { db in
            try TransactionReceipt.filter(TransactionReceipt.Columns.transactionHash == hash).fetchOne(db)
        }
    }

    func save(logs: [TransactionLog]) {
        try! dbPool.write { db in
            for log in logs {
                try log.insert(db)
            }
        }
    }

    func save(internalTransactions: [InternalTransaction]) {
        _ = try? dbPool.write { db in
            for internalTransaction in internalTransactions {
                try internalTransaction.insert(db)
            }
        }
    }

    func set(tags: [TransactionTag]) {
        _ = try? dbPool.write { db in
            for tag in tags {
                try tag.save(db)
            }
        }
    }

    func remove(logs: [TransactionLog]) {
        try! dbPool.write { db in
            for log in logs {
                try log.delete(db)
            }
        }
    }

    func hashesFromTransactions() -> [Data] {
        try! dbPool.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT \(Transaction.Columns.hash.name) FROM \(Transaction.databaseTableName)")
            return rows.compactMap {
                $0[Transaction.Columns.hash.name] as? Data
            }
        }
    }

    func transactionsBeforeSingle(tags: [[String]], hash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        Single.create { [weak self] observer in
            guard let storage = self else {
                observer(.success([]))
                return Disposables.create()
            }

            let transactions: [Transaction] = try! storage.dbPool.read { db in
                var whereConditions = [String]()
                
                if tags.count > 0 {
                    let tagConditions = tags
                        .enumerated()
                        .map { (index, andTags) -> String in
                            "\(TransactionTag.databaseTableName)_\(index).'\(TransactionTag.Columns.name)' IN (\(andTags.map({ "'\($0)'" }).joined(separator: ", ")))"
                        }
                        .joined(separator: " AND ")
                    
                    whereConditions.append(tagConditions)
                }
                
                if let fromHash = hash,
                   let fromTransaction = try Transaction.filter(Transaction.Columns.hash == fromHash).fetchOne(db) {
                    let transactionIndex = (try fromTransaction.receipt.fetchOne(db))?.transactionIndex ?? 0

                    let fromCondition = """
                                   (
                                    \(Transaction.Columns.timestamp.name) < \(fromTransaction.timestamp) OR 
                                        (
                                            \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) = \(fromTransaction.timestamp) AND 
                                            \(TransactionReceipt.databaseTableName).\(TransactionReceipt.Columns.transactionIndex.name) < \(transactionIndex)
                                        )
                                   )
                                   """
                    
                    whereConditions.append(fromCondition)
                }

                let transactionTagJoinStatements = tags
                    .enumerated()
                    .map { (index, _) -> String in
                        "INNER JOIN transaction_tags AS transaction_tags_\(index) ON transactions.hash = transaction_tags_\(index).transactionHash"
                    }
                    .joined(separator: "\n")

                var limitClause = ""
                if let limit = limit {
                    limitClause += "LIMIT \(limit)"
                }

                let orderClause = """
                                  ORDER BY \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) DESC, 
                                  \(TransactionReceipt.databaseTableName).\(TransactionReceipt.Columns.transactionIndex.name) DESC
                                  """

                let whereClause = whereConditions.count > 0 ? "WHERE \(whereConditions.joined(separator: " AND "))" : ""

                let sql = """
                          SELECT transactions.*
                          FROM transactions
                          \(transactionTagJoinStatements)
                          LEFT JOIN transaction_receipts ON transactions.hash = transaction_receipts.transactionHash
                          \(whereClause)
                          GROUP BY transactions.hash
                          \(orderClause)
                          \(limitClause)
                          """

                let rows = try Row.fetchAll(db.makeSelectStatement(sql: sql))
                return rows.map { row -> Transaction in
                    Transaction(row: row)
                }
            }

            observer(.success(storage.fullTransactions(from: transactions)))

            return Disposables.create()
        }
    }

    func pendingTransactions(tags: [[String]]) -> [FullTransaction] {
        let transactions: [Transaction] = try! dbPool.read { db in
            var whereConditions = [String]()
            var transactionTagJoinStatements = ""
    
            if tags.count > 0 {
                let tagConditions = tags
                    .enumerated()
                    .map { (index, andTags) -> String in
                        "\(TransactionTag.databaseTableName)_\(index).'\(TransactionTag.Columns.name)' IN (\(andTags.map({ "'\($0)'" }).joined(separator: ", ")))"
                    }
                    .joined(separator: " AND ")
                
                whereConditions.append(tagConditions)
                
                transactionTagJoinStatements += tags
                    .enumerated()
                    .map { (index, _) -> String in
                        "INNER JOIN transaction_tags AS transaction_tags_\(index) ON transactions.hash = transaction_tags_\(index).transactionHash"
                    }
                    .joined(separator: "\n")
            }
            
            whereConditions.append("\(TransactionReceipt.databaseTableName).\(TransactionReceipt.Columns.status.name) IS NULL")
            
            let whereClause = whereConditions.count > 0 ? "WHERE \(whereConditions.joined(separator: " AND "))" : ""

            let sql = """
                      SELECT transactions.*
                      FROM transactions
                      \(transactionTagJoinStatements)
                      LEFT JOIN transaction_receipts ON transactions.hash = transaction_receipts.transactionHash
                      \(whereClause)
                      GROUP BY transactions.hash
                      """

            let rows = try Row.fetchAll(db.makeSelectStatement(sql: sql))
            return rows.map { row -> Transaction in
                Transaction(row: row)
            }
        }

        return fullTransactions(from: transactions)
    }

    func transaction(hash: Data) -> FullTransaction? {
        fullTransactions(byHashes: [hash]).first
    }

    func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        let transactions = try! dbPool.read { db in
            try Transaction.filter(hashes.contains(Transaction.Columns.hash)).fetchAll(db)
        }

        return fullTransactions(from: transactions)
    }

    func add(droppedTransaction: DroppedTransaction) {
        _ = try? dbPool.write { db in
            try droppedTransaction.insert(db)
        }
    }
}

extension TransactionStorage: ITransactionSyncerStateStorage {

    func transactionSyncerState(id: String) -> TransactionSyncerState? {
        try! dbPool.read { db in
            try TransactionSyncerState.filter(TransactionSyncerState.Columns.id == id).fetchOne(db)
        }
    }

    func save(transactionSyncerState: TransactionSyncerState) {
        try! dbPool.write { db in
            try transactionSyncerState.save(db)
        }
    }

}

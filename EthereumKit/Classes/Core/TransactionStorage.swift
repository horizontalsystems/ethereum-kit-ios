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

        migrator.registerMigration("Remove old tables") { db in
            if try db.tableExists("transactions") { try db.drop(table: "transactions") }
            if try db.tableExists("internal_transactions") { try db.drop(table: "internal_transactions") }
            if try db.tableExists("transaction_receipts") { try db.drop(table: "transaction_receipts") }
            if try db.tableExists("transaction_logs") { try db.drop(table: "transaction_logs") }
            if try db.tableExists("not_synced_internal_transactions") { try db.drop(table: "not_synced_internal_transactions") }
            if try db.tableExists("not_synced_transactions") { try db.drop(table: "not_synced_transactions") }
            if try db.tableExists("transaction_syncer_states") { try db.drop(table: "transaction_syncer_states") }
            if try db.tableExists("dropped_transactions") { try db.drop(table: "dropped_transactions") }
            if try db.tableExists("transaction_tags") { try db.drop(table: "transaction_tags") }
        }

        migrator.registerMigration("Create Transaction") { db in
            try db.create(table: Transaction.databaseTableName) { t in
                t.column(Transaction.Columns.hash.name, .text).notNull()
                t.column(Transaction.Columns.timestamp.name, .integer).notNull()
                t.column(Transaction.Columns.isFailed.name, .boolean).notNull()
                t.column(Transaction.Columns.blockNumber.name, .integer)
                t.column(Transaction.Columns.transactionIndex.name, .integer)
                t.column(Transaction.Columns.from.name, .text)
                t.column(Transaction.Columns.to.name, .text)
                t.column(Transaction.Columns.value.name, .text)
                t.column(Transaction.Columns.input.name, .text)
                t.column(Transaction.Columns.nonce.name, .integer)
                t.column(Transaction.Columns.gasPrice.name, .integer)
                t.column(Transaction.Columns.maxFeePerGas.name, .integer)
                t.column(Transaction.Columns.maxPriorityFeePerGas.name, .integer)
                t.column(Transaction.Columns.gasLimit.name, .integer)
                t.column(Transaction.Columns.gasUsed.name, .integer)
                t.column(Transaction.Columns.replacedWith.name, .text)

                t.primaryKey([Transaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("create InternalTransaction") { db in
            try db.create(table: InternalTransaction.databaseTableName) { t in
                t.column(InternalTransaction.Columns.hash.name, .text).notNull()
                t.column(InternalTransaction.Columns.from.name, .text).notNull()
                t.column(InternalTransaction.Columns.to.name, .text).notNull()
                t.column(InternalTransaction.Columns.value.name, .text).notNull()
                t.column(InternalTransaction.Columns.traceId.name, .text).notNull()

                t.primaryKey([InternalTransaction.Columns.hash.name, InternalTransaction.Columns.traceId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("create TransactionTag") { db in
            try db.create(table: TransactionTag.databaseTableName) { t in
                t.column(TransactionTag.Columns.name.name, .text).notNull().indexed()
                t.column(TransactionTag.Columns.transactionHash.name, .text).notNull()

                t.uniqueKey([TransactionTag.Columns.name.name, TransactionTag.Columns.transactionHash.name], onConflict: .ignore)
            }
        }

        return migrator
    }

}

extension TransactionStorage: ITransactionStorage {

    func lastTransaction() -> Transaction? {
        try! dbPool.read { db in
            try Transaction
                    .filter(Transaction.Columns.blockNumber != nil)
                    .order(Transaction.Columns.blockNumber.desc)
                    .fetchOne(db)
        }
    }

    func transaction(hash: Data) -> Transaction? {
        try! dbPool.read { db in
            try Transaction
                    .filter(Transaction.Columns.hash == hash)
                    .fetchOne(db)
        }
    }

    func transactions(hashes: [Data]) -> [Transaction] {
        try! dbPool.read { db in
            try Transaction
                    .filter(hashes.contains(Transaction.Columns.hash))
                    .fetchAll(db)
        }
    }

    func transactionsBefore(tags: [[String]], hash: Data?, limit: Int?) -> [Transaction] {
        try! dbPool.read { db in
            var arguments = [DatabaseValueConvertible]()
            var whereConditions = [String]()

            if tags.count > 0 {
                let tagConditions = tags.enumerated()
                        .map { index, andTags -> String in
                            arguments.append(contentsOf: andTags)
                            let inStatement = andTags.map({ _ in "?" }).joined(separator: ", ")
                            return "\(TransactionTag.databaseTableName)_\(index).'\(TransactionTag.Columns.name.name)' IN (\(inStatement))"
                        }
                        .joined(separator: " AND ")

                whereConditions.append(tagConditions)
            }

            if let fromHash = hash,
               let fromTransaction = try Transaction.filter(Transaction.Columns.hash == fromHash).fetchOne(db) {
                let transactionIndex = fromTransaction.transactionIndex ?? 0

                let fromCondition = """
                                    (
                                     \(Transaction.Columns.timestamp.name) < ? OR
                                         (
                                             \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) = ? AND
                                             \(Transaction.databaseTableName).\(Transaction.Columns.transactionIndex.name) < ?
                                         ) OR
                                         (
                                             \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) = ? AND
                                             \(Transaction.databaseTableName).\(Transaction.Columns.transactionIndex.name) IS ? AND
                                             \(Transaction.databaseTableName).\(Transaction.Columns.hash.name) < ?
                                         )
                                    )
                                    """

                arguments.append(fromTransaction.timestamp)
                arguments.append(fromTransaction.timestamp)
                arguments.append(transactionIndex)
                arguments.append(fromTransaction.timestamp)
                arguments.append(transactionIndex)
                arguments.append(fromTransaction.hash)

                whereConditions.append(fromCondition)
            }

            let transactionTagJoinStatements = tags
                    .enumerated()
                    .map { (index, _) -> String in
                        "INNER JOIN \(TransactionTag.databaseTableName) AS \(TransactionTag.databaseTableName)_\(index) ON \(Transaction.databaseTableName).\(Transaction.Columns.hash.name) = \(TransactionTag.databaseTableName)_\(index).\(TransactionTag.Columns.transactionHash.name)"
                    }
                    .joined(separator: "\n")

            var limitClause = ""
            if let limit = limit {
                limitClause += "LIMIT \(limit)"
            }

            let orderClause = """
                              ORDER BY \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) DESC,
                              \(Transaction.databaseTableName).\(Transaction.Columns.transactionIndex.name) DESC,
                              \(Transaction.databaseTableName).\(Transaction.Columns.hash.name) DESC
                              """

            let whereClause = whereConditions.count > 0 ? "WHERE \(whereConditions.joined(separator: " AND "))" : ""

            let sql = """
                      SELECT \(Transaction.databaseTableName).*
                      FROM \(Transaction.databaseTableName)
                      \(transactionTagJoinStatements)
                      \(whereClause)
                      \(orderClause)
                      \(limitClause)
                      """

            let rows = try Row.fetchAll(db.makeSelectStatement(sql: sql), arguments: StatementArguments(arguments))
            return rows.map { row -> Transaction in
                Transaction(row: row)
            }
        }
    }

    func save(transactions: [Transaction]) {
        try! dbPool.write { db in
            for transaction in transactions {
                try transaction.save(db)
            }
        }
    }

    func pendingTransactions() -> [Transaction] {
        try! dbPool.read { db in
            try Transaction
                    .filter(Transaction.Columns.blockNumber == nil && Transaction.Columns.isFailed == false)
                    .fetchAll(db)
        }
    }

    func pendingTransactions(tags: [[String]]) -> [Transaction] {
        try! dbPool.read { db in
            var arguments = [DatabaseValueConvertible]()
            var whereConditions = [String]()
            var transactionTagJoinStatements = ""

            if tags.count > 0 {
                let tagConditions = tags.enumerated()
                        .map { (index, andTags) -> String in
                            arguments.append(contentsOf: andTags)
                            let inStatement = andTags.map({ _ in "?" }).joined(separator: ", ")
                            return "\(TransactionTag.databaseTableName)_\(index).'\(TransactionTag.Columns.name.name)' IN (\(inStatement))"
                        }
                        .joined(separator: " AND ")

                whereConditions.append(tagConditions)

                transactionTagJoinStatements += tags
                        .enumerated()
                        .map { (index, _) -> String in
                            "INNER JOIN \(TransactionTag.databaseTableName) AS \(TransactionTag.databaseTableName)_\(index) ON \(Transaction.databaseTableName).\(Transaction.Columns.hash.name) = \(TransactionTag.databaseTableName)_\(index).\(TransactionTag.Columns.transactionHash.name)"
                        }
                        .joined(separator: "\n")
            }

            whereConditions.append("\(Transaction.databaseTableName).\(Transaction.Columns.blockNumber.name) IS NULL")

            let whereClause = whereConditions.count > 0 ? "WHERE \(whereConditions.joined(separator: " AND "))" : ""

            let sql = """
                      SELECT \(Transaction.databaseTableName).*
                      FROM \(Transaction.databaseTableName)
                      \(transactionTagJoinStatements)
                      \(whereClause)
                      """

            let rows = try Row.fetchAll(db.makeSelectStatement(sql: sql), arguments: StatementArguments(arguments))
            return rows.map { row -> Transaction in
                Transaction(row: row)
            }
        }
    }

    func nonPendingTransactions(nonces: [Int]) -> [Transaction] {
        try! dbPool.read { db in
            try Transaction
                    .filter(Transaction.Columns.blockNumber != nil && nonces.contains(Transaction.Columns.nonce))
                    .fetchAll(db)
        }
    }

    func internalTransactions() -> [InternalTransaction] {
        try! dbPool.read { db in
            try InternalTransaction.fetchAll(db)
        }
    }

    func internalTransactions(hashes: [Data]) -> [InternalTransaction] {
        try! dbPool.read { db in
            try InternalTransaction
                    .filter(hashes.contains(InternalTransaction.Columns.hash))
                    .fetchAll(db)
        }
    }

    func save(internalTransactions: [InternalTransaction]) {
        try! dbPool.write { db in
            for internalTransaction in internalTransactions {
                try internalTransaction.save(db)
            }
        }
    }

    func save(tags: [TransactionTag]) {
        try! dbPool.write { db in
            for tag in tags {
                try tag.save(db)
            }
        }
    }

}

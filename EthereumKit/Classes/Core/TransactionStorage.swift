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

        migrator.registerMigration("add blockNumber column to InternalTransaction") { db in
            try db.alter(table: InternalTransaction.databaseTableName) { t in
                t.add(column: InternalTransaction.Columns.blockNumber.name, .integer).notNull().defaults(to: 0)
            }
        }

        migrator.registerMigration("truncate Transaction, InternalTransaction, TransactionTag") { db in
            try Transaction.deleteAll(db)
            try InternalTransaction.deleteAll(db)
        }

        migrator.registerMigration("create TransactionTagRecord") { db in
            if try db.tableExists("transactionTags") {
                try db.drop(table: "transactionTags")
            }

            try Transaction.deleteAll(db)
            try InternalTransaction.deleteAll(db)

            try db.create(table: TransactionTagRecord.databaseTableName) { t in
                t.column(TransactionTagRecord.Columns.transactionHash.name, .blob).notNull()
                t.column(TransactionTagRecord.Columns.type.name, .text).notNull()
                t.column(TransactionTagRecord.Columns.protocol.name, .text)
                t.column(TransactionTagRecord.Columns.contractAddress.name, .blob)
            }
        }

        return migrator
    }

}

extension TransactionStorage {

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

    func transactionsBefore(tagQueries: [TransactionTagQuery], hash: Data?, limit: Int?) -> [Transaction] {
        try! dbPool.read { db in
            var arguments = [DatabaseValueConvertible]()
            var whereConditions = [String]()
            let queries = tagQueries.filter { !$0.isEmpty }
            var joinClause = ""

            if !queries.isEmpty {
                let tagConditions = queries
                        .map { (tagQuery: TransactionTagQuery) -> String in
                            var statements = [String]()

                            if let type = tagQuery.type {
                                statements.append("\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.type.name)' = ?")
                                arguments.append(type)
                            }
                            if let `protocol` = tagQuery.protocol {
                                statements.append("\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.protocol.name)' = ?")
                                arguments.append(`protocol`)
                            }
                            if let contractAddress = tagQuery.contractAddress {
                                statements.append("\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.contractAddress.name)' = ?")
                                arguments.append(contractAddress)
                            }

                            return "(\(statements.joined(separator: " AND ")))"
                        }
                        .joined(separator: " OR ")

                whereConditions.append(tagConditions)
                joinClause = "INNER JOIN \(TransactionTagRecord.databaseTableName) ON \(Transaction.databaseTableName).\(Transaction.Columns.hash.name) = \(TransactionTagRecord.databaseTableName).\(TransactionTagRecord.Columns.transactionHash.name)"
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
                      SELECT DISTINCT \(Transaction.databaseTableName).*
                      FROM \(Transaction.databaseTableName)
                      \(joinClause)
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

    func pendingTransactions(tagQueries: [TransactionTagQuery]) -> [Transaction] {
        try! dbPool.read { db in
            var arguments = [DatabaseValueConvertible]()
            var whereConditions = [String]()
            let queries = tagQueries.filter { !$0.isEmpty }
            var joinClause = ""

            if !queries.isEmpty {
                let tagConditions = queries
                        .map { (tagQuery: TransactionTagQuery) -> String in
                            var statements = [String]()

                            if let type = tagQuery.type {
                                statements.append("\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.type.name)' = ?")
                                arguments.append(type)
                            }
                            if let `protocol` = tagQuery.protocol {
                                statements.append("\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.protocol.name)' = ?")
                                arguments.append(`protocol`)
                            }
                            if let contractAddress = tagQuery.contractAddress {
                                statements.append("\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.contractAddress.name)' = ?")
                                arguments.append(contractAddress)
                            }

                            return "(\(statements.joined(separator: " AND ")))"
                        }
                        .joined(separator: " OR ")

                whereConditions.append(tagConditions)
                joinClause = "INNER JOIN \(TransactionTagRecord.databaseTableName) ON \(Transaction.databaseTableName).\(Transaction.Columns.hash.name) = \(TransactionTagRecord.databaseTableName).\(TransactionTagRecord.Columns.transactionHash.name)"
            }

            whereConditions.append("\(Transaction.databaseTableName).\(Transaction.Columns.blockNumber.name) IS NULL")

            let whereClause = whereConditions.count > 0 ? "WHERE \(whereConditions.joined(separator: " AND "))" : ""

            let sql = """
                      SELECT \(Transaction.databaseTableName).*
                      FROM \(Transaction.databaseTableName)
                      \(joinClause)
                      \(whereClause)
                      """

            let rows = try Row.fetchAll(db.makeSelectStatement(sql: sql), arguments: StatementArguments(arguments))
            return rows.map { row -> Transaction in
                Transaction(row: row)
            }
        }
    }

    func nonPendingTransactions(from: Address, nonces: [Int]) -> [Transaction] {
        try! dbPool.read { db in
            try Transaction
                    .filter(Transaction.Columns.from == from.raw && Transaction.Columns.blockNumber != nil && nonces.contains(Transaction.Columns.nonce))
                    .fetchAll(db)
        }
    }

    func lastInternalTransaction() -> InternalTransaction? {
        try! dbPool.read { db in
            try InternalTransaction
                    .filter(InternalTransaction.Columns.blockNumber != nil)
                    .order(Transaction.Columns.blockNumber.desc)
                    .fetchOne(db)
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

    func tagTokens() throws -> [TagToken] {
        try dbPool.write { db in
            let request = TransactionTagRecord
                    .filter(TransactionTagRecord.Columns.protocol != nil)
                    .select(TransactionTagRecord.Columns.protocol, TransactionTagRecord.Columns.contractAddress)
                    .distinct()
            let rows = try Row.fetchAll(db, request)

            return rows.compactMap { row in
                TagToken(protocol: row[0], contractAddress: row[1])
            }
        }
    }

    func save(tags: [TransactionTagRecord]) {
        try! dbPool.write { db in
            for tag in tags {
                try tag.save(db)
            }
        }
    }

}

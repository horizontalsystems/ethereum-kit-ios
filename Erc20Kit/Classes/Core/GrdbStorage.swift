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

}

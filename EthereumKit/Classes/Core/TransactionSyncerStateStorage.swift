import RxSwift
import GRDB

class TransactionSyncerStateStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create TransactionSyncerState") { db in
            try db.create(table: TransactionSyncerState.databaseTableName) { t in
                t.column(TransactionSyncerState.Columns.syncerId.name, .text).notNull().indexed()
                t.column(TransactionSyncerState.Columns.lastBlockNumber.name, .integer).notNull()

                t.uniqueKey([TransactionSyncerState.Columns.syncerId.name, TransactionSyncerState.Columns.lastBlockNumber.name], onConflict: .ignore)
            }
        }

        return migrator
    }

}

extension TransactionSyncerStateStorage {

    func syncerState(syncerId: String) throws -> TransactionSyncerState? {
        try dbPool.read { db in
            try TransactionSyncerState.filter(TransactionSyncerState.Columns.syncerId == syncerId).fetchOne(db)
        }
    }

    func save(syncerState: TransactionSyncerState) throws {
        try dbPool.write { db in
            try syncerState.save(db)
        }
    }

}

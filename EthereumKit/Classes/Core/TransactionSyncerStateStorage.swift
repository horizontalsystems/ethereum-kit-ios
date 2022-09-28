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

        migrator.registerMigration("recreate TransactionSyncerState") { db in
            var oldStates = [TransactionSyncerState]()

            if try db.tableExists(TransactionSyncerState.databaseTableName) {
                oldStates = try TransactionSyncerState.fetchAll(db)

                try db.drop(table: TransactionSyncerState.databaseTableName)
            }

            try db.create(table: TransactionSyncerState.databaseTableName) { t in
                t.column(TransactionSyncerState.Columns.syncerId.name, .text).primaryKey(onConflict: .replace)
                t.column(TransactionSyncerState.Columns.lastBlockNumber.name, .integer).notNull()
            }

            for oldState in oldStates {
                try oldState.insert(db)
            }
        }

        migrator.registerMigration("truncate TransactionSyncerState") { db in
            try TransactionSyncerState.deleteAll(db)
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

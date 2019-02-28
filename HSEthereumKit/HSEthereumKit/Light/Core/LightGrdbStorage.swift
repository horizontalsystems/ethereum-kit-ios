import Foundation
import GRDB

class LightGrdbStorage: GrdbStorage, ILightStorage {

    override init(databaseFileName: String) {
        super.init(databaseFileName: databaseFileName)

        try? lightMigrator.migrate(dbPool)
    }

    var lightMigrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createBlockHeaders") { db in
            try db.create(table: BlockHeader.databaseTableName) { t in
                t.column(BlockHeader.Columns.hashHex.name, .blob).notNull()
                t.column(BlockHeader.Columns.totalDifficulty.name, .blob).notNull()
                t.column(BlockHeader.Columns.parentHash.name, .blob).notNull()
                t.column(BlockHeader.Columns.unclesHash.name, .blob).notNull()
                t.column(BlockHeader.Columns.coinbase.name, .blob).notNull()
                t.column(BlockHeader.Columns.stateRoot.name, .blob).notNull()
                t.column(BlockHeader.Columns.transactionsRoot.name, .blob).notNull()
                t.column(BlockHeader.Columns.receiptsRoot.name, .blob).notNull()
                t.column(BlockHeader.Columns.logsBloom.name, .blob).notNull()
                t.column(BlockHeader.Columns.difficulty.name, .blob).notNull()
                t.column(BlockHeader.Columns.height.name, .text).notNull()
                t.column(BlockHeader.Columns.gasLimit.name, .blob).notNull()
                t.column(BlockHeader.Columns.gasUsed.name, .integer).notNull()
                t.column(BlockHeader.Columns.timestamp.name, .integer).notNull()
                t.column(BlockHeader.Columns.extraData.name, .blob).notNull()
                t.column(BlockHeader.Columns.mixHash.name, .blob).notNull()
                t.column(BlockHeader.Columns.nonce.name, .blob).notNull()

                t.primaryKey([BlockHeader.Columns.hashHex.name], onConflict: .replace)
            }
        }

        return migrator
    }

    override func clear() {
        _ = try? dbPool.write { db in
            try BlockHeader.deleteAll(db)
        }

        super.clear()
    }

    func lastBlockHeader() -> BlockHeader? {
        return try! dbPool.read { db in
            try BlockHeader.order(Column("height").desc).fetchOne(db)
        }
    }

    func save(blockHeaders: [BlockHeader]) {
        _ = try? dbPool.write { db in
            for header in blockHeaders {
                print(header.toString())
                try header.insert(db)
            }
        }
    }

}

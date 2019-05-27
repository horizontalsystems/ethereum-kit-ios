import RxSwift
import GRDB

class SpvStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createBlockHeaders") { db in
            try db.create(table: BlockHeader.databaseTableName) { t in
                t.column(BlockHeader.Columns.hashHex.name, .blob).notNull()
                t.column(BlockHeader.Columns.totalDifficulty.name, .text).notNull()
                t.column(BlockHeader.Columns.parentHash.name, .blob).notNull()
                t.column(BlockHeader.Columns.unclesHash.name, .blob).notNull()
                t.column(BlockHeader.Columns.coinbase.name, .blob).notNull()
                t.column(BlockHeader.Columns.stateRoot.name, .blob).notNull()
                t.column(BlockHeader.Columns.transactionsRoot.name, .blob).notNull()
                t.column(BlockHeader.Columns.receiptsRoot.name, .blob).notNull()
                t.column(BlockHeader.Columns.logsBloom.name, .blob).notNull()
                t.column(BlockHeader.Columns.difficulty.name, .text).notNull()
                t.column(BlockHeader.Columns.height.name, .integer).notNull()
                t.column(BlockHeader.Columns.gasLimit.name, .integer).notNull()
                t.column(BlockHeader.Columns.gasUsed.name, .integer).notNull()
                t.column(BlockHeader.Columns.timestamp.name, .integer).notNull()
                t.column(BlockHeader.Columns.extraData.name, .blob).notNull()
                t.column(BlockHeader.Columns.mixHash.name, .blob).notNull()
                t.column(BlockHeader.Columns.nonce.name, .blob).notNull()

                t.primaryKey([BlockHeader.Columns.height.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createAccountStates") { db in
            try db.create(table: AccountState.databaseTableName) { t in
                t.column(AccountState.Columns.address.name, .blob).notNull()
                t.column(AccountState.Columns.nonce.name, .integer).notNull()
                t.column(AccountState.Columns.balance.name, .text).notNull()
                t.column(AccountState.Columns.storageHash.name, .blob).notNull()
                t.column(AccountState.Columns.codeHash.name, .blob).notNull()

                t.primaryKey([AccountState.Columns.address.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension SpvStorage: ISpvStorage {

    // BlockHeader

    var lastBlockHeader: BlockHeader? {
        return try! dbPool.read { db in
            try BlockHeader.order(Column("height").desc).fetchOne(db)
        }
    }

    func blockHeader(height: Int) -> BlockHeader? {
        return try! dbPool.read { db in
            try BlockHeader.filter(BlockHeader.Columns.height == height).fetchOne(db)
        }
    }

    func reversedLastBlockHeaders(from height: Int, limit: Int) -> [BlockHeader] {
        return try! dbPool.read { db in
            try BlockHeader.filter(BlockHeader.Columns.height <= height).order(Column("height").desc).limit(limit).fetchAll(db)
        }
    }

    func save(blockHeaders: [BlockHeader]) {
        _ = try? dbPool.write { db in
            for header in blockHeaders {
                try header.insert(db)
            }
        }
    }

    // AccountState

    var accountState: AccountState? {
        return try! dbPool.read { db in
            try AccountState.fetchOne(db)
        }
    }

    func save(accountState: AccountState) {
        _ = try? dbPool.write { db in
            try accountState.insert(db)
        }
    }

}

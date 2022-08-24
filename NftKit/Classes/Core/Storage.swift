import GRDB
import BigInt

class Storage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create Eip721Event") { db in
            try db.create(table: Eip721Event.databaseTableName) { t in
                t.column(Eip721Event.Columns.hash.name, .text).notNull()
                t.column(Eip721Event.Columns.blockNumber.name, .integer).notNull()
                t.column(Eip721Event.Columns.contractAddress.name, .text).notNull()
                t.column(Eip721Event.Columns.from.name, .text).notNull()
                t.column(Eip721Event.Columns.to.name, .text).notNull()
                t.column(Eip721Event.Columns.tokenId.name, .text).notNull()
                t.column(Eip721Event.Columns.tokenName.name, .text).notNull()
                t.column(Eip721Event.Columns.tokenSymbol.name, .text).notNull()
                t.column(Eip721Event.Columns.tokenDecimal.name, .text).notNull()
            }
        }

        migrator.registerMigration("create Eip1155Event") { db in
            try db.create(table: Eip1155Event.databaseTableName) { t in
                t.column(Eip1155Event.Columns.hash.name, .text).notNull()
                t.column(Eip1155Event.Columns.blockNumber.name, .integer).notNull()
                t.column(Eip1155Event.Columns.contractAddress.name, .text).notNull()
                t.column(Eip1155Event.Columns.from.name, .text).notNull()
                t.column(Eip1155Event.Columns.to.name, .text).notNull()
                t.column(Eip1155Event.Columns.tokenId.name, .text).notNull()
                t.column(Eip1155Event.Columns.tokenValue.name, .integer).notNull()
                t.column(Eip1155Event.Columns.tokenName.name, .text).notNull()
                t.column(Eip1155Event.Columns.tokenSymbol.name, .text).notNull()
            }
        }

        return migrator
    }

}

extension Storage {

    func lastEip721Event() -> Eip721Event? {
        try! dbPool.read { db in
            try Eip721Event.order(Eip721Event.Columns.blockNumber.desc).fetchOne(db)
        }
    }

    func eip721Events() -> [Eip721Event] {
        try! dbPool.read { db in
            try Eip721Event.fetchAll(db)
        }
    }

    func eip721Events(hashes: [Data]) -> [Eip721Event] {
        try! dbPool.read { db in
            try Eip721Event
                    .filter(hashes.contains(Eip721Event.Columns.hash))
                    .fetchAll(db)
        }
    }

    func save(eip721Events: [Eip721Event]) {
        try! dbPool.write { db in
            for event in eip721Events {
                try event.save(db)
            }
        }
    }

    func lastEip1155Event() -> Eip1155Event? {
        try! dbPool.read { db in
            try Eip1155Event.order(Eip1155Event.Columns.blockNumber.desc).fetchOne(db)
        }
    }

    func eip1155Events() -> [Eip1155Event] {
        try! dbPool.read { db in
            try Eip1155Event.fetchAll(db)
        }
    }

    func eip1155Events(hashes: [Data]) -> [Eip1155Event] {
        try! dbPool.read { db in
            try Eip1155Event
                    .filter(hashes.contains(Eip1155Event.Columns.hash))
                    .fetchAll(db)
        }
    }

    func save(eip1155Events: [Eip1155Event]) {
        try! dbPool.write { db in
            for event in eip1155Events {
                try event.save(db)
            }
        }
    }

}

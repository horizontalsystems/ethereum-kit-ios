import GRDB
import BigInt

class Eip20Storage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createEip20Balances") { db in
            try db.create(table: Eip20Balance.databaseTableName) { t in
                t.column(Eip20Balance.Columns.contractAddress.name, .text).notNull()
                t.column(Eip20Balance.Columns.value.name, .text)

                t.primaryKey([Eip20Balance.Columns.contractAddress.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("create Event") { db in
            try db.create(table: Event.databaseTableName) { t in
                t.column(Event.Columns.hash.name, .text).notNull()
                t.column(Event.Columns.contractAddress.name, .text).notNull()
                t.column(Event.Columns.from.name, .text).notNull()
                t.column(Event.Columns.to.name, .text).notNull()
                t.column(Event.Columns.value.name, .text).notNull()
                t.column(Event.Columns.tokenName.name, .text).notNull()
                t.column(Event.Columns.tokenSymbol.name, .text).notNull()
                t.column(Event.Columns.tokenDecimal.name, .text).notNull()
            }
        }

        migrator.registerMigration("add blockNumber to Event") { db in
            try db.alter(table: Event.databaseTableName) { t in
                t.add(column: Event.Columns.blockNumber.name, .integer).notNull().defaults(to: 0)
            }
        }

        migrator.registerMigration("truncate Event") { db in
            try Event.deleteAll(db)
        }

        return migrator
    }

}

extension Eip20Storage {

    func balance(contractAddress: Address) -> BigUInt? {
        try! dbPool.read { db in
            try Eip20Balance.filter(Eip20Balance.Columns.contractAddress == contractAddress.hex).fetchOne(db)?.value
        }
    }

    func save(balance: BigUInt, contractAddress: Address) {
        _ = try? dbPool.write { db in
            try Eip20Balance(contractAddress: contractAddress.hex, value: balance).insert(db)
        }
    }

    func lastEvent() -> Event? {
        try! dbPool.read { db in
            try Event.order(Transaction.Columns.blockNumber.desc).fetchOne(db)
        }
    }

    func events() -> [Event] {
        try! dbPool.read { db in
            try Event.fetchAll(db)
        }
    }

    func events(hashes: [Data]) -> [Event] {
        try! dbPool.read { db in
            try Event
                    .filter(hashes.contains(Event.Columns.hash))
                    .fetchAll(db)
        }
    }

    func save(events: [Event]) {
        try! dbPool.write { db in
            for event in events {
                try event.save(db)
            }
        }
    }

}

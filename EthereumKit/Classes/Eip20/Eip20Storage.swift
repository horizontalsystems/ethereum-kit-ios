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

}

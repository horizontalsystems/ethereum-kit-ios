import RxSwift
import GRDB
import BigInt

class ApiGrdbStorage: BaseGrdbStorage {

    override var migrator: DatabaseMigrator {
        var migrator = super.migrator

        migrator.registerMigration("createBalances") { db in
            try db.create(table: EthereumBalance.databaseTableName) { t in
                t.column(EthereumBalance.Columns.address.name, .text).notNull()
                t.column(EthereumBalance.Columns.value.name, .text).notNull()

                t.primaryKey([EthereumBalance.Columns.address.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createBlockchainStates") { db in
            try db.create(table: BlockchainState.databaseTableName) { t in
                t.column(BlockchainState.Columns.primaryKey.name, .text).notNull()
                t.column(BlockchainState.Columns.lastBlockHeight.name, .integer)

                t.primaryKey([BlockchainState.Columns.primaryKey.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension ApiGrdbStorage: IApiStorage {

    var lastBlockHeight: Int? {
        return try! dbPool.read { db in
            try BlockchainState.fetchOne(db)?.lastBlockHeight
        }
    }

    func save(lastBlockHeight: Int) {
        _ = try? dbPool.write { db in
            let state = try BlockchainState.fetchOne(db) ?? BlockchainState()
            state.lastBlockHeight = lastBlockHeight
            try state.insert(db)
        }
    }

    func balance(forAddress address: Data) -> BigUInt? {
        let request = EthereumBalance.filter(EthereumBalance.Columns.address == address)

        return try! dbPool.read { db in
            try request.fetchOne(db)?.value
        }
    }

    func save(balance: BigUInt, address: Data) {
        _ = try? dbPool.write { db in
            let balanceObject = EthereumBalance(address: address, value: balance)
            try balanceObject.insert(db)
        }
    }

    func lastTransactionBlockHeight() -> Int? {
        return try! dbPool.read { db in
            return try Transaction.order(Transaction.Columns.blockNumber.desc).fetchOne(db)?.blockNumber
        }
    }

}

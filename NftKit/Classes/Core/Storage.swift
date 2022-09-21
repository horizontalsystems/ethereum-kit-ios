import GRDB
import BigInt
import EthereumKit

class Storage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create NftBalance") { db in
            try db.create(table: NftBalance.databaseTableName) { t in
                t.column(NftBalance.Columns.type.name, .text).notNull()
                t.column(NftBalance.Columns.contractAddress.name, .text).notNull()
                t.column(NftBalance.Columns.tokenId.name, .text).notNull()
                t.column(NftBalance.Columns.tokenName.name, .text).notNull()
                t.column(NftBalance.Columns.balance.name, .integer).notNull()
                t.column(NftBalance.Columns.synced.name, .boolean).notNull()

                t.primaryKey([NftBalance.Columns.contractAddress.name, NftBalance.Columns.tokenId.name], onConflict: .replace)
            }
        }

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

    private func filter(nft: Nft) -> SQLSpecificExpressible {
        var conditions: [SQLSpecificExpressible] = [
            NftBalance.Columns.contractAddress == nft.contractAddress.raw,
            NftBalance.Columns.tokenId == nft.tokenId
        ]

        return conditions.joined(operator: .and)
    }

}

extension Storage {

    func nftBalances(type: NftType) throws -> [NftBalance] {
        try dbPool.read { db in
            try NftBalance.filter(NftBalance.Columns.type == type).fetchAll(db)
        }
    }

    func existingNftBalances() throws -> [NftBalance] {
        try dbPool.read { db in
            try NftBalance.filter(NftBalance.Columns.balance > 0).fetchAll(db)
        }
    }

    func nonSyncedNftBalances() throws -> [NftBalance] {
        try dbPool.read { db in
            try NftBalance.filter(NftBalance.Columns.synced == false).fetchAll(db)
        }
    }

    func existingNftBalance(contractAddress: Address, tokenId: BigUInt) throws -> NftBalance? {
        try dbPool.read { db in
            try NftBalance.filter(NftBalance.Columns.contractAddress == contractAddress.raw && NftBalance.Columns.tokenId == tokenId && NftBalance.Columns.balance > 0).fetchOne(db)
        }
    }

    func setNotSynced(nfts: [Nft]) throws {
        try dbPool.write { db in
            try NftBalance
                    .filter(nfts.map { filter(nft: $0) }.joined(operator: .or))
                    .updateAll(db, NftBalance.Columns.synced.set(to: false))
        }
    }

    func setSynced(balanceInfos: [(Nft, Int)]) throws {
        try dbPool.write { db in
            for balanceInfo in balanceInfos {
                let (nft, balance) = balanceInfo

                try NftBalance
                        .filter(filter(nft: nft))
                        .updateAll(db,
                                NftBalance.Columns.synced.set(to: true),
                                NftBalance.Columns.balance.set(to: balance)
                        )
            }
        }
    }

    func save(nftBalances: [NftBalance]) throws {
        try dbPool.write { db in
            for nftBalance in nftBalances {
                try nftBalance.save(db)
            }
        }
    }

    func lastEip721Event() throws -> Eip721Event? {
        try dbPool.read { db in
            try Eip721Event.order(Eip721Event.Columns.blockNumber.desc).fetchOne(db)
        }
    }

    func eip721Events() throws -> [Eip721Event] {
        try dbPool.read { db in
            try Eip721Event.fetchAll(db)
        }
    }

    func eip721Events(hashes: [Data]) throws -> [Eip721Event] {
        try dbPool.read { db in
            try Eip721Event
                    .filter(hashes.contains(Eip721Event.Columns.hash))
                    .fetchAll(db)
        }
    }

    func save(eip721Events: [Eip721Event]) throws {
        try dbPool.write { db in
            for event in eip721Events {
                try event.save(db)
            }
        }
    }

    func lastEip1155Event() throws -> Eip1155Event? {
        try dbPool.read { db in
            try Eip1155Event.order(Eip1155Event.Columns.blockNumber.desc).fetchOne(db)
        }
    }

    func eip1155Events() throws -> [Eip1155Event] {
        try dbPool.read { db in
            try Eip1155Event.fetchAll(db)
        }
    }

    func eip1155Events(hashes: [Data]) throws -> [Eip1155Event] {
        try dbPool.read { db in
            try Eip1155Event
                    .filter(hashes.contains(Eip1155Event.Columns.hash))
                    .fetchAll(db)
        }
    }

    func save(eip1155Events: [Eip1155Event]) throws {
        try dbPool.write { db in
            for event in eip1155Events {
                try event.save(db)
            }
        }
    }

}

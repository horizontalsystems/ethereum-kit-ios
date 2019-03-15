import Foundation
import RxSwift
import GRDB

class SpvGrdbStorage {
    internal let dbPool: DatabasePool

    init(databaseFileName: String) {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createTransactions") { db in
            try db.create(table: EthereumTransaction.databaseTableName) { t in
                t.column(EthereumTransaction.Columns.hash.name, .text).notNull()
                t.column(EthereumTransaction.Columns.nonce.name, .integer).notNull()
                t.column(EthereumTransaction.Columns.input.name, .text).notNull()
                t.column(EthereumTransaction.Columns.from.name, .text).notNull()
                t.column(EthereumTransaction.Columns.to.name, .text).notNull()
                t.column(EthereumTransaction.Columns.amount.name, .text).notNull()
                t.column(EthereumTransaction.Columns.gasLimit.name, .integer).notNull()
                t.column(EthereumTransaction.Columns.gasPriceInWei.name, .integer).notNull()
                t.column(EthereumTransaction.Columns.timestamp.name, .double).notNull()
                t.column(EthereumTransaction.Columns.contractAddress.name, .text).notNull()
                t.column(EthereumTransaction.Columns.blockHash.name, .text)
                t.column(EthereumTransaction.Columns.blockNumber.name, .integer)
                t.column(EthereumTransaction.Columns.confirmations.name, .integer)
                t.column(EthereumTransaction.Columns.gasUsed.name, .integer)
                t.column(EthereumTransaction.Columns.cumulativeGasUsed.name, .integer)
                t.column(EthereumTransaction.Columns.isError.name, .boolean)
                t.column(EthereumTransaction.Columns.transactionIndex.name, .integer)
                t.column(EthereumTransaction.Columns.txReceiptStatus.name, .boolean)

                t.primaryKey([EthereumTransaction.Columns.hash.name, EthereumTransaction.Columns.contractAddress.name], onConflict: .replace)
            }
        }

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
                t.column(BlockHeader.Columns.height.name, .text).notNull()
                t.column(BlockHeader.Columns.gasLimit.name, .integer).notNull()
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

}

extension SpvGrdbStorage: ISpvStorage {

    var lastBlockHeight: Int? {
        return lastBlockHeader?.height.toInt()
    }

    func balance(forAddress address: String) -> String? {
        return nil
    }

    func transactionsSingle(fromHash: String?, limit: Int?, contractAddress: String?) -> Single<[EthereumTransaction]> {
        return Single.create { [weak self] observer in
            try? self?.dbPool.read { db in
                var request = EthereumTransaction.all()

                if let contractAddress = contractAddress {
                    request = request.filter(EthereumTransaction.Columns.contractAddress == contractAddress)
                } else {
                    request = request.filter(EthereumTransaction.Columns.contractAddress == "" && EthereumTransaction.Columns.input == "0x")
                }

                if let fromHash = fromHash, let fromTransaction = try request.filter(EthereumTransaction.Columns.hash == fromHash).fetchOne(db) {
                    request = request.filter(EthereumTransaction.Columns.timestamp < fromTransaction.timestamp)
                }
                if let limit = limit {
                    request = request.limit(limit)
                }

                let transactions = try request.order(EthereumTransaction.Columns.timestamp.desc).fetchAll(db)

                observer(.success(transactions))
            }

            return Disposables.create()
        }
    }

    func clear() {
        _ = try? dbPool.write { db in
            try EthereumTransaction.deleteAll(db)
            try BlockHeader.deleteAll(db)
        }
    }

    var lastBlockHeader: BlockHeader? {
        return try! dbPool.read { db in
            try BlockHeader.order(Column("height").desc).fetchOne(db)
        }
    }

    func save(blockHeaders: [BlockHeader]) {
        _ = try? dbPool.write { db in
            for header in blockHeaders {
                try header.insert(db)
            }
        }
    }

}

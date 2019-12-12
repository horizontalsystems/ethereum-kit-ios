import RxSwift
import GRDB

class DiscoveryStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createNodes") { db in
            try db.create(table: NodeRecord.databaseTableName) { t in
                t.column(NodeRecord.Columns.id.name, .text).notNull()
                t.column(NodeRecord.Columns.host.name, .text).notNull()
                t.column(NodeRecord.Columns.port.name, .integer).notNull()
                t.column(NodeRecord.Columns.discoveryPort.name, .integer).notNull()
                t.column(NodeRecord.Columns.used.name, .boolean).notNull()
                t.column(NodeRecord.Columns.score.name, .integer).notNull()
                t.column(NodeRecord.Columns.eligible.name, .boolean).notNull()
                t.column(NodeRecord.Columns.timestamp.name, .integer).notNull()

                t.primaryKey([NodeRecord.Columns.id.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension DiscoveryStorage: IDiscoveryStorage {

    func leastScoreNode(excludingIds: [Data]) -> NodeRecord? {
        return try! dbPool.read { db in
            try NodeRecord
                    .filter(!excludingIds.contains(NodeRecord.Columns.id))
                    .filter(NodeRecord.Columns.eligible == true)
                    .order(NodeRecord.Columns.score.asc)
                    .fetchOne(db)
        }
    }

    func increasePeerAddressScore(id: Data) {
        _ = try! dbPool.write { db in
            if let node = try NodeRecord.filter(NodeRecord.Columns.id == id).fetchOne(db) {
                node.score += 1
                try node.save(db)
            }
        }
    }

    func markNodeNonEligible(id: Data) {
        _ = try! dbPool.write { db in
            if let node = try NodeRecord.filter(NodeRecord.Columns.id == id).fetchOne(db) {
                node.eligible = false
                try node.save(db)
            }
        }
    }

    func save(nodes: [NodeRecord]) {
        _ = try! dbPool.write { db in
            for node in nodes {
                try node.insert(db)
            }
        }
    }

    func remove(node: Node) {
        _ = try! dbPool.write { db in
            try NodeRecord.filter(NodeRecord.Columns.id == node.id).deleteAll(db)
        }

    }


    func nonUsedNode() -> NodeRecord? {
        return try! dbPool.read { db in
            return try NodeRecord.filter(NodeRecord.Columns.used == false).order(NodeRecord.Columns.timestamp.asc).fetchOne(db)
        }
    }

    func contain(nodeId: Data) -> Bool {
        return try! dbPool.read { db in
            try NodeRecord.filter(NodeRecord.Columns.id == nodeId).fetchOne(db)
        } != nil
    }

    func setNonEligible(node: NodeRecord) {
        node.eligible = false
        _ = try! dbPool.write { db in
            try node.update(db)
        }
    }

    func setUsed(node: NodeRecord) {
        node.used = true
        _ = try! dbPool.write { db in
            try node.update(db)
        }
    }

}

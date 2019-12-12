import GRDB
import BigInt

class NodeRecord: Record {
    let id: Data
    let host: String
    let port: Int
    let discoveryPort: Int

    var used: Bool
    var eligible: Bool
    var score: Int
    let timestamp: Int

    init(id: Data, host: String, port: Int, discoveryPort: Int, used: Bool, eligible: Bool, score: Int, timestamp: Int) {
        self.id = id
        self.host = host
        self.port = port
        self.discoveryPort = discoveryPort

        self.used = used
        self.eligible = eligible
        self.score = score
        self.timestamp = timestamp

        super.init()
    }

    override class var databaseTableName: String {
        return "node_discovered"
    }

    enum Columns: String, ColumnExpression {
        case id
        case host
        case port
        case discoveryPort

        case score
        case used
        case eligible
        case timestamp
    }

    required init(row: Row) {
        id = row[Columns.id]
        host = row[Columns.host]
        port = row[Columns.port]
        discoveryPort = row[Columns.discoveryPort]
        score = row[Columns.score]
        used = row[Columns.used]
        eligible = row[Columns.eligible]
        timestamp = row[Columns.timestamp]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.host] = host
        container[Columns.port] = port
        container[Columns.discoveryPort] = discoveryPort
        container[Columns.used] = used
        container[Columns.score] = score
        container[Columns.eligible] = eligible
        container[Columns.timestamp] = timestamp
    }

    func toString() -> String {
        return "(\n" +
                "  id: \(id.toHexString())\n" +
                "  address: \(host):\(port) | :\(discoveryPort)\n" +
                "  used: \(used) - eligible: \(eligible)\n" +
                "  score: \(score) - timestamp: \(timestamp)\n" +
                ")"
    }

}

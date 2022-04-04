import GRDB

public class TransactionTag: Record {
    public static let evmCoin = "ETH"

    let name: String
    let transactionHash: Data

    init(name: String, transactionHash: Data) {
        self.name = name
        self.transactionHash = transactionHash

        super.init()
    }

    public override class var databaseTableName: String {
        "transactionTags"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case name
        case transactionHash
    }

    required init(row: Row) {
        name = row[Columns.name]
        transactionHash = row[Columns.transactionHash]

        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.name] = name
        container[Columns.transactionHash] = transactionHash
    }

}

extension TransactionTag: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine("\(name)\(transactionHash.hex)")
    }

    public static func ==(lhs: TransactionTag, rhs: TransactionTag) -> Bool {
        lhs.name == rhs.name && lhs.transactionHash == rhs.transactionHash
    }

}

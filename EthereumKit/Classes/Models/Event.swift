import GRDB
import BigInt

public class Event: Record {
    public let hash: Data
    public let contractAddress: Address
    public let from: Address
    public let to: Address
    public let value: BigUInt
    public let tokenName: String
    public let tokenSymbol: String
    public let tokenDecimal: Int

    public init(hash: Data, contractAddress: Address, from: Address, to: Address, value: BigUInt, tokenName: String, tokenSymbol: String, tokenDecimal: Int) {
        self.hash = hash
        self.contractAddress = contractAddress
        self.from = from
        self.to = to
        self.value = value
        self.tokenName = tokenName
        self.tokenSymbol = tokenSymbol
        self.tokenDecimal = tokenDecimal

        super.init()
    }

    override public class var databaseTableName: String {
        "events"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case contractAddress
        case from
        case to
        case value
        case tokenName
        case tokenSymbol
        case tokenDecimal
    }

    required public init(row: Row) {
        hash = row[Columns.hash]
        contractAddress = Address(raw: row[Columns.contractAddress])
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        value = row[Columns.value]
        tokenName = row[Columns.tokenName]
        tokenSymbol = row[Columns.tokenSymbol]
        tokenDecimal = row[Columns.tokenDecimal]

        super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.contractAddress] = contractAddress.raw
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.value] = value
        container[Columns.tokenName] = tokenName
        container[Columns.tokenSymbol] = tokenSymbol
        container[Columns.tokenDecimal] = tokenDecimal
    }

}

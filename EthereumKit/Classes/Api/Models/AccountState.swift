import GRDB
import BigInt

public class AccountState: Record {
    private static let primaryKey = "primaryKey"

    private let primaryKey: String = AccountState.primaryKey

    public let balance: BigUInt
    public let nonce: Int

    init(balance: BigUInt, nonce: Int) {
        self.balance = balance
        self.nonce = nonce

        super.init()
    }

    override class public var databaseTableName: String {
        "account_states"
    }

    enum Columns: String, ColumnExpression {
        case primaryKey
        case balance
        case nonce
    }

    required init(row: Row) {
        balance = row[Columns.balance]
        nonce = row[Columns.nonce]

        super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.primaryKey] = primaryKey
        container[Columns.balance] = balance
        container[Columns.nonce] = nonce
    }

}

extension AccountState: Equatable {

    public static func ==(lhs: AccountState, rhs: AccountState) -> Bool {
        lhs.balance == rhs.balance && lhs.nonce == lhs.nonce
    }

}

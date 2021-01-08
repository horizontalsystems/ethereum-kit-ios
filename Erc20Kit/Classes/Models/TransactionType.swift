import GRDB

public enum TransactionType: String, DatabaseValueConvertible {
    case transfer = "transfer"
    case approve = "approve"

    public var databaseValue: DatabaseValue {
        self.rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> TransactionType? {
        if case let DatabaseValue.Storage.string(value) = dbValue.storage {
            return TransactionType(rawValue: value)
        }

        return nil
    }

}

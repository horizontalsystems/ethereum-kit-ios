import GRDB

public enum NftType: String {
    case eip721
    case eip1155
}

extension NftType: DatabaseValueConvertible {

    public var databaseValue: DatabaseValue {
        self.rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> NftType? {
        guard let rawValue = String.fromDatabaseValue(dbValue) else {
            return nil
        }

        return NftType(rawValue: rawValue)
    }

}

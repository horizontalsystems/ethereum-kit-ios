import GRDB
import BigInt

extension UInt16 {
    
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
    
}

extension BigUInt: DatabaseValueConvertible {

    /// Returns a value that can be stored in the database.
    public var databaseValue: DatabaseValue {
        return self.description.databaseValue
    }

    /// Returns a value initialized from dbValue, if possible.
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> BigUInt? {
        if case let DatabaseValue.Storage.string(value) = dbValue.storage {
            return BigUInt(value)
        }

        return nil
    }

}

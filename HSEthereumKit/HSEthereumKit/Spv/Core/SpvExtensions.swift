import GRDB

extension UInt16 {
    
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
    
}

extension BInt: DatabaseValueConvertible {

    /// Returns a value that can be stored in the database.
    public var databaseValue: DatabaseValue {
        return self.asString(withBase: 10).databaseValue
    }

    /// Returns a value initialized from dbValue, if possible.
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> BInt? {
        if case let DatabaseValue.Storage.string(value) = dbValue.storage {
            return BInt(value, radix: 10)
        }

        return nil
    }

}
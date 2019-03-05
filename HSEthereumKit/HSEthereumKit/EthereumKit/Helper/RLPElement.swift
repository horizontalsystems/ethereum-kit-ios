import Foundation

class RLPElement {

    let type: RLP.ElementType
    let lengthOfLengthBytes: Int
    let length: Int
    let dataValue: Data

    private let _listValue: [RLPElement]?

    func listValue() throws -> [RLPElement] {
        guard type == .list, let list = _listValue else {
            throw RLP.DecodeError.invalidListValue
        }

        return list
    }

    func intValue() throws -> Int {
        guard type == .string else {
            throw RLP.DecodeError.invalidIntValue
        }

        if length == 0 {
            return 0
        }

        guard let int = Int(dataValue.toHexString(), radix: 16) else {
            throw RLP.DecodeError.invalidIntValue
        }

        return int
    }

    func bIntValue() throws -> BInt {
        guard type == .string else {
            throw RLP.DecodeError.invalidBIntValue
        }

        if length == 0 {
            return 0
        }

        guard let bInt = BInt(dataValue.toHexString(), radix: 16) else {
            throw RLP.DecodeError.invalidBIntValue
        }

        return bInt
    }

    func stringValue() throws -> String {
        guard type == .string else {
            throw RLP.DecodeError.invalidStringValue
        }

        if length == 0 {
            return ""
        }

        guard let str = String(data: dataValue, encoding: .utf8) else {
            throw RLP.DecodeError.invalidStringValue
        }

        return str
    }

    init(type: RLP.ElementType, length: Int, lengthOfLengthBytes: Int, dataValue: Data, listValue: [RLPElement]?) {
        self.type = type
        self.length = length
        self.lengthOfLengthBytes = lengthOfLengthBytes
        self.dataValue = dataValue
        self._listValue = listValue
    }

    func isList() -> Bool {
        return type == .list
    }

}

import Foundation

enum RLPElementType {
    case string
    case list
}

class RLPElement {

    let type: RLPElementType
    let lengthOfLengthBytes: Int
    let length: Int
    let dataValue: Data
    let listValue: [RLPElement]

    var intValue: Int {
        if length == 0 {
            return 0
        }

        if let int = Int(dataValue.toHexString(), radix: 16) {
            return int
        } else {
            return 0
        }
    }

    var bIntValue: BInt {
        if length == 0 {
            return 0
        }

        if let bInt = BInt(dataValue.toHexString(), radix: 16) {
            return bInt
        } else {
            return 0
        }
    }

    var stringValue: String {
        return String(data: dataValue, encoding: .utf8) ?? ""
    }

    init(type: RLPElementType, length: Int, lengthOfLengthBytes: Int, dataValue: Data, listValue: [RLPElement]) {
        self.type = type
        self.length = length
        self.lengthOfLengthBytes = lengthOfLengthBytes
        self.dataValue = dataValue
        self.listValue = listValue
    }

    func isList() -> Bool {
        return type == .list
    }

}

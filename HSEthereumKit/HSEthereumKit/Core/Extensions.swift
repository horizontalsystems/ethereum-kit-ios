extension Data {

    public init(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                self = Data()
                return
            }
        }
        self = data
    }

    public var bytes: Array<UInt8> {
        return Array(self)
    }

    public func toHexString() -> String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }

}

extension Data {

    init?(hex: String) {
        let hex = hex.stripHexPrefix()

        let len = hex.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }

        self = data
    }

    func toHexString() -> String {
        return "0x" + self.toRawHexString()
    }

    func toRawHexString() -> String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }

    func toEIP55Address() -> String {
        return EIP55.format(address: self.toRawHexString())
    }

    var bytes: Array<UInt8> {
        return Array(self)
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }

}

extension Int {

    var flowControlLog: String {
        return "\(Double(self) / 1_000_000)"
    }

}

extension String {

    func stripHexPrefix() -> String {
        let prefix = "0x"

        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        }

        return self
    }

    func addHexPrefix() -> String {
        let prefix = "0x"

        if self.hasPrefix(prefix) {
            return self
        }

        return prefix.appending(self)
    }

}

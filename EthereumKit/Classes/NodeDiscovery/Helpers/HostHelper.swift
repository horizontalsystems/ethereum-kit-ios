// packet = packet-header || packet-data

// packet-header = hash || signature || packet-type
// hash = keccak256(signature || packet-type || packet-data)
// signature = sign(packet-type || packet-data)
enum HostDecodeError: Error {
    case tooSmall
    case emptyData
    case wrongRecipientData
    case wrongHash
    case wrongType
}


class HostHelper {

    static func decode(host: String) -> Data? {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else {
            return nil
        }
        var data = Data()
        for part in parts {
            guard let number = UInt8(part) else {
                return nil
            }
            data.append(number)
        }
        return data
    }

    static func encode(host: Data) -> String? {
        guard host.count == 4 else {
            return nil
        }
        let parts = [UInt8](host).map { "\($0)" }
        return parts.joined(separator: ".")
    }

}

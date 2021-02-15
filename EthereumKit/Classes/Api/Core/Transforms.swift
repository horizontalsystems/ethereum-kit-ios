import BigInt
import ObjectMapper

struct HexIntTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> Int? {
        guard let hexString = value as? String else {
            return nil
        }

        return Int(hexString.stripHexPrefix(), radix: 16)
    }

    func transformToJSON(_ value: Int?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }

}

struct HexStringTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> String? {
        value as? String
    }

    func transformToJSON(_ value: String?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }

}

struct HexDataArrayTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> [Data]? {
        guard let hexStrings = value as? [String] else {
            return nil
        }

        return hexStrings.compactMap { Data(hex: $0) }
    }

    func transformToJSON(_ value: [Data]?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }

}

struct HexDataTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> Data? {
        guard let hexString = value as? String else {
            return nil
        }

        return Data(hex: hexString)
    }

    func transformToJSON(_ value: Data?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }

}

struct HexAddressTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> Address? {
        guard let hexString = value as? String else {
            return nil
        }

        return try? Address(hex: hexString)
    }

    func transformToJSON(_ value: Address?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }

}

struct HexBigUIntTransform: TransformType {

    func transformFromJSON(_ value: Any?) -> BigUInt? {
        guard let hexString = value as? String else {
            return nil
        }

        return BigUInt(hexString.stripHexPrefix(), radix: 16)
    }

    func transformToJSON(_ value: BigUInt?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }

}

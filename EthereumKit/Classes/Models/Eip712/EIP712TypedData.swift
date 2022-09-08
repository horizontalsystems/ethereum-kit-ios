import Foundation
import BigInt

public struct EIP712Type: Codable {
    let name: String
    let type: String
}

public struct EIP712Domain: Codable {
    let name: String
    let version: String
    let chainId: Int
    let verifyingContract: String
}

public struct EIP712TypedData: Codable {
    public let types: [String: [EIP712Type]]
    public let primaryType: String
    public let domain: JSON
    public let message: JSON
}

extension EIP712TypedData {

    public var typeHash: Data {
        encodeType(primaryType: primaryType).sha3
    }

    public func signHash() throws -> Data {
        let data = try Data(bytes: [0x19, 0x01]) + encodeData(data: domain, type: "EIP712Domain").sha3 + encodeData(data: message, type: primaryType).sha3
        return data.sha3
    }

    func findDependencies(primaryType: String, dependencies: Set<String> = Set<String>()) -> Set<String> {
        var found = dependencies
        var primaryType = primaryType

        let components = primaryType.components(separatedBy: "[")
        if components.count == 2 {
            primaryType = components[0]
        }

        guard !found.contains(primaryType), let primaryTypes = types[primaryType] else {
            return found
        }

        found.insert(primaryType)

        for type in primaryTypes {
            findDependencies(primaryType: type.type, dependencies: found).forEach { found.insert($0) }
        }

        return found
    }

    public func encodeType(primaryType: String) -> Data {
        var depSet = findDependencies(primaryType: primaryType)
        depSet.remove(primaryType)

        let sorted = [primaryType] + Array(depSet).sorted()
        let encoded = sorted.map { type in
            let param = types[type]!.map { "\($0.type) \($0.name)" }.joined(separator: ",")
            return "\(type)(\(param))"
        }.joined()

        return encoded.data(using: .utf8) ?? Data()
    }

    public func encodeData(data: JSON, type: String) throws -> Data {
        let encoder = ABIEncoder()
        var values: [ABIValue] = []

        let typeHash = encodeType(primaryType: type).sha3
        let typeHashValue = try ABIValue(typeHash, type: .bytes(32))
        values.append(typeHashValue)

        if let valueTypes = types[type] {
            try valueTypes.forEach { field in
                let value = try encodeField(name: field.name, rawType: field.type, value: data[field.name] ?? JSON.null)
                values.append(value)
            }
        }

        try encoder.encode(tuple: values)

        return encoder.data
    }

    private func encodeField(name: String, rawType: String, value: JSON) throws -> ABIValue {
//        print("ENCODE FIELD: \(rawType) --- \(name) --- \(value)")
        if types[rawType] != nil {
//            print("custom")
            let typeValue: Data

            if value == .null {
                typeValue = Data("0x0000000000000000000000000000000000000000000000000000000000000000".utf8)
            } else {
                typeValue = try encodeData(data: value, type: rawType).sha3
            }

            return try ABIValue(typeValue, type: .bytes(32))
        }

        if case let .array(jsons) = value {
            let components = rawType.components(separatedBy: CharacterSet(charactersIn: "[]"))

            if components.count == 3 && components[1].isEmpty {
//                print("array regular")
                let rawType = components[0]
                let encoder = ABIEncoder()
                let values = try jsons.map {
                    try encodeField(name: name, rawType: rawType, value: $0)
                }
                try encoder.encode(tuple: values)
                return try ABIValue(encoder.data.sha3, type: .bytes(32))
            } else if components.count == 3 && !components[1].isEmpty {
//                print("array indexed")
                let num = String(components[1].filter { "0"..."9" ~= $0 })

                guard Int(num) != nil else {
                    throw AbiError.invalidArrayIndex
                }

                let rawType = components[0]
                let encoder = ABIEncoder()
                let values = try jsons.map {
                    try encodeField(name: name, rawType: rawType, value: $0)
                }
                try encoder.encode(tuple: values)
                return try ABIValue(encoder.data.sha3, type: .bytes(32))
            } else {
                throw AbiError.invalidArray
            }
        }

//        print("regular")
        return try makeABIValue(name: name, data: value, type: rawType)
    }

    private func makeABIValue(name: String, data: JSON?, type: String) throws -> ABIValue {
        if type == "string", let value = data?.stringValue, let valueData = value.data(using: .utf8) {
            return try ABIValue(valueData.sha3, type: .bytes(32))
        } else if type == "bytes", let value = data?.stringValue, let valueData = Data(hex: value) {
            return try ABIValue(valueData.sha3, type: .bytes(32))
        } else if type == "bool", let value = data?.boolValue {
            return try ABIValue(value, type: .bool)
        } else if type == "address", let value = data?.stringValue, let address = EthereumAddress(string: value) {
            return try ABIValue(address, type: .address)
        } else if type.starts(with: "uint") {
            let size = try parseIntSize(type: type, prefix: "uint")
            if let value = data?.floatValue {
                return try ABIValue(Int(value), type: .uint(bits: size))
            } else if let value = data?.stringValue, let bigInt = BigUInt(value: value) {
                return try ABIValue(bigInt, type: .uint(bits: size))
            }
        } else if type.starts(with: "int") {
            let size = try parseIntSize(type: type, prefix: "int")
            if let value = data?.floatValue {
                return try ABIValue(Int(value), type: .int(bits: size))
            } else if let value = data?.stringValue, let bigInt = BigInt(value: value) {
                return try ABIValue(bigInt, type: .int(bits: size))
            }
        } else if type.starts(with: "bytes") {
            if let length = Int(type.dropFirst("bytes".count)), let value = data?.stringValue {
                if value.starts(with: "0x"), let hex = Data(hex: value) {
                    return try ABIValue(hex, type: .bytes(length))
                } else {
                    return try ABIValue(Data(bytes: Array(value.utf8)), type: .bytes(length))
                }
            }
        }

        throw AbiError.invalidAbi
    }

    private func parseIntSize(type: String, prefix: String) throws -> Int {
        guard type.starts(with: prefix), let size = Int(type.dropFirst(prefix.count)) else {
            throw AbiError.invalidIntSize
        }

        if size < 8 || size > 256 || size % 8 != 0 {
            throw AbiError.invalidIntSize
        }

        return size
    }

    enum AbiError: Error {
        case invalidIntSize
        case invalidArray
        case invalidArrayIndex
        case invalidAbi
    }

}

private extension BigInt {

    init?(value: String) {
        if value.starts(with: "0x") {
            self.init(String(value.dropFirst(2)), radix: 16)
        } else {
            self.init(value)
        }
    }

}

private extension BigUInt {

    init?(value: String) {
        if value.starts(with: "0x") {
            self.init(String(value.dropFirst(2)), radix: 16)
        } else {
            self.init(value)
        }
    }

}

private extension Data {

    var sha3: Data {
        CryptoUtils.shared.sha3(self)
    }

}

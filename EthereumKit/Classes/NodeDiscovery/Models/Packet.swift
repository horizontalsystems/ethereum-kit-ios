import OpenSslKit
import Secp256k1Kit

//packet-header = hash || signature || packet-type
//hash = keccak256(signature || packet-type || packet-data)
//signature = sign(packet-type || packet-data)

struct Packet {
    let hash: Data
    let signature: Data
    let type: UInt8

    let package: IPackage
}

enum PacketParseError: Error {
    case tooSmall
    case wrongHash
    case wrongType
}

class PacketParser: IPacketParser {
    static let macSize  = 32
    static let sigSize  = 65
    static let headSize = macSize + sigSize // space of packet frame data


    let packageParsers: [UInt8: IPackageParser]

    init(parsers: [UInt8: IPackageParser]) {
        self.packageParsers = parsers
    }

    func parse(data: Data) throws -> Packet {
        guard data.count > PacketParser.headSize + 1 else {
            throw PacketParseError.tooSmall
        }
        let hash = data.prefix(PacketParser.macSize)
        let forHash = data.subdata(in: PacketParser.macSize..<data.count)
        let sig = data.subdata(in: PacketParser.macSize..<PacketParser.headSize)
        let type = data[PacketParser.headSize]

        let shouldHash = OpenSslKit.Kit.sha3(forHash)

        guard shouldHash == hash else {
            throw PacketParseError.wrongHash
        }

        let packageData = data.subdata(in: (PacketParser.headSize + 1)..<data.count)
        guard let parser = packageParsers[type] else {
            throw PacketParseError.wrongType
        }
        let package = try parser.parse(data: packageData)
        return Packet(hash: hash, signature: sig, type: type, package: package)
    }

}

enum PacketSerializeError: Error {
    case wrongType
    case emptyPackageData
    case signError
}

class PacketSerializer: IPacketSerializer {
    let privateKey: Data
    let packageSerializers: [IPackageSerializer]

    init(serializers: [IPackageSerializer], privateKey: Data) {
        self.packageSerializers = serializers
        self.privateKey = privateKey
    }

    func serialize(package: IPackage) throws -> Data {
        let type = Data(from: package.type)

        var data = Data()
        var lastError: Error? = nil
        for serializer in packageSerializers {
            do {
                data = try serializer.serialize(package: package)
            } catch {
                lastError = error
            }
        }
        if data.isEmpty {
            throw lastError ?? PacketSerializeError.emptyPackageData
        }
        let typeAndData = type + data

        // make signature
        guard let sign = try? Secp256k1Kit.Kit.ellipticSign(CryptoUtils.shared.sha3(typeAndData), privateKey: privateKey) else {
            throw PacketSerializeError.signError
        }

        // make hash
        let hash = CryptoUtils.shared.sha3(sign + typeAndData)

        // make packet-header
        let packetHeader = hash + sign + type

        // make packet
        return packetHeader + data
    }

}

import HdWalletKit

// packet-data = [version, from, to, expiration, ...]
// version = 4
// from = [sender-ip, sender-udp-port, sender-tcp-port]
// to = [recipient-ip, recipient-udp-port, 0]

struct PingPackage: IPackage {
    static let version = 4

    let type: UInt8 = 1

    let from: Node
    let to: Node

    let expiration: Int32
}

struct PongPackage: IPackage {
    let type: UInt8 = 2

    let to: Node
    let pingHash: Data

    let expiration: Int32
}

struct FindNodePackage: IPackage {
    let type: UInt8 = 3

    let target: Data

    let expiration: Int32
}

struct NeighborsPackage: IPackage {
    let type: UInt8 = 4

    let nodes: [Node]

    let expiration: Int32
}

enum PackageSerializeError: Error {
    case wrongHostDecode
    case wrongSerializer
}

class PingPackageSerializer: IPackageSerializer {

    func serialize(package: IPackage) throws -> Data {
        guard let package = package as? PingPackage else {
            throw PackageSerializeError.wrongSerializer
        }
        guard let fromData = HostHelper.decode(host: package.from.host), let toData = HostHelper.decode(host: package.to.host) else {
            throw PackageSerializeError.wrongHostDecode
        }
        let senderData: [Any] = [fromData, package.from.discoveryPort, package.from.port]
        let recipientData: [Any] = [toData, package.to.discoveryPort, 0]

        return RLP.encode([PingPackage.version, senderData, recipientData, Data(Data(from: package.expiration).reversed())])
    }

}

class PongPackageSerializer: IPackageSerializer {

    func serialize(package: IPackage) throws -> Data {
        guard let package = package as? PongPackage else {
            throw PackageSerializeError.wrongSerializer
        }
        guard let toData = HostHelper.decode(host: package.to.host) else {
            throw PackageSerializeError.wrongHostDecode
        }
        let recipientData: [Any] = [toData, package.to.discoveryPort, package.to.port]

        return RLP.encode([recipientData, package.pingHash, Data(Data(from: package.expiration).reversed())])
    }

}

class FindNodePackageSerializer: IPackageSerializer {

    func serialize(package: IPackage) throws -> Data {
        guard let package = package as? FindNodePackage else {
            throw PackageSerializeError.wrongSerializer
        }
        return RLP.encode([package.target, Data(Data(from: package.expiration).reversed())])
    }

}

enum PackageParseError: Error {
    case emptyPackage
    case wrongParameters
    case wrongVersion
}

class PingPackageParser: IPackageParser {

    func parse(data: Data) throws -> IPackage {
        guard !data.isEmpty else {
            throw PackageParseError.emptyPackage
        }
        let rlpDecoded = try RLP.decode(input: data).listValue()

        guard rlpDecoded.count >= 4 else {
            throw HostDecodeError.emptyData
        }
        // version
        let version = try rlpDecoded[0].intValue()
        guard version == PingPackage.version else {
            throw PackageParseError.wrongVersion
        }
        // from = [sender-ip, sender-udp-port, sender-tcp-port]

        let fromList = try rlpDecoded[1].listValue()
        guard fromList.count == 3, let fromHost = HostHelper.encode(host: fromList[0].dataValue) else {
            throw PackageParseError.wrongParameters
        }
        let from = Node(id: Data(), host: fromHost, port: try fromList[2].intValue(), discoveryPort: try fromList[1].intValue())

        // to = [recipient-ip, recipient-udp-port, 0]

        let toList = try rlpDecoded[2].listValue()
        guard toList.count == 3, let toHost = HostHelper.encode(host: toList[0].dataValue) else {
            throw PackageParseError.wrongParameters
        }
        let to = Node(id: Data(), host: toHost, port: try toList[2].intValue(), discoveryPort: try toList[1].intValue())

        let expiration = try rlpDecoded[3].intValue()

        return PingPackage(from: from, to: to, expiration: Int32(expiration))
    }

}

class PongPackageParser: IPackageParser {

    func parse(data: Data) throws -> IPackage {
        guard !data.isEmpty else {
            throw PackageParseError.emptyPackage
        }
        let rlpDecoded = try RLP.decode(input: data).listValue()

        guard rlpDecoded.count >= 3 else {
            throw HostDecodeError.emptyData
        }
        let toList = try rlpDecoded[0].listValue()
        guard toList.count == 3 else {
            throw PackageParseError.wrongParameters
        }
        // to = [recipient-ip, recipient-udp-port, 0]
        guard let host = HostHelper.encode(host: toList[0].dataValue) else {
            throw PackageParseError.wrongParameters
        }
        let to = Node(id: Data(), host: host, port: try toList[2].intValue(), discoveryPort: try toList[1].intValue())

        let hash = rlpDecoded[1].dataValue
        let expiration = try rlpDecoded[2].intValue()

        return PongPackage(to: to, pingHash: hash, expiration: Int32(expiration))
    }

}

class NeighborsPackageParser: IPackageParser {

    func parse(data: Data) throws -> IPackage {
        guard !data.isEmpty else {
            throw PackageParseError.emptyPackage
        }
        let rlpDecoded = try RLP.decode(input: data).listValue()

        guard rlpDecoded.count >= 2 else {
            throw PackageParseError.wrongParameters
        }
        // version
        let nodesList = try rlpDecoded[0].listValue()
        var nodes = [Node]()
        for i in 0..<nodesList.count {
            let nodeData = try nodesList[i].listValue()
            guard nodeData.count == 4, let host = HostHelper.encode(host: nodeData[0].dataValue) else {
                throw PackageParseError.wrongParameters
            }

            let node = Node(id: nodeData[3].dataValue, host: host, port: try nodeData[2].intValue(), discoveryPort: try nodeData[1].intValue())
            nodes.append(node)
        }

        let expiration = try rlpDecoded[1].intValue()

        return NeighborsPackage(nodes: nodes, expiration: Int32(expiration))
    }

}

import Foundation

// ParseV4 parses a node URL.
//
// There are two basic forms of node URLs:
//
//   - incomplete nodes, which only have the public key (node ID)
//   - complete nodes, which contain the public key and IP/Port information
//
// For incomplete nodes, the designator must look like one of these
//
//    enode://<hex node id>
//    <hex node id>
//
// For complete nodes, the node ID is encoded in the username portion
// of the URL, separated from the host by an @ sign. The hostname can
// only be given as an IP address, DNS domain names are not allowed.
// The port in the host name section is the TCP listening port. If the
// TCP and UDP (discovery) ports differ, the UDP port is specified as
// query parameter "discport".
//
// In the following example, the node URL describes
// a node with IP address 10.3.58.6, TCP listening port 30303
// and UDP discovery port 30301.
//
//    enode://<hex node id>@10.3.58.6:30303?discport=30301
enum NodeParsingError: Error {
    case emptyNodeId
    case wrongNodeId
}
class NodeParser: INodeParser {

    func parse(uri: String) throws -> Node {
        var host = ""
        var port = 0
        var discPort = 0

        var parseString = uri
        // If uri has prefix, drop it
        if parseString.prefix(8) == "enode://" {
            parseString = String(parseString.dropFirst(8))
        }
        // Split string by @. First part will be node Id, second contains [host, port, discPort]
        let idParsed = parseString.split(separator: "@")
        // Check array has at least 1 element(node Id)
        guard !idParsed.isEmpty else {
            throw NodeParsingError.emptyNodeId
        }
        // Check id contains only hex symbols
        guard let id = Data(hex: String(idParsed[0])) else {
            throw NodeParsingError.wrongNodeId
        }
        // Uri can contains only 1 '@' symbol, so if it has part after - try parse host
        if idParsed.count >= 2 {
            // Split by host-port separator
            var hostParsed = idParsed[1].split(separator: ":").map { String($0) }


            // If can't find part after ':' then try find and parse discPort separated by '?'
            guard hostParsed.count >= 2 else {
                if let discoveryPort = parseDiscoveryPort(uri: &hostParsed[0]) {
                    discPort = discoveryPort
                }
                host = correct(host: hostParsed[0])
                return Node(id: id, host: host, port: port, discoveryPort: discPort)
            }
            host = correct(host: hostParsed[0])
            // Parse ports. "123[?discport=456]
            let discoveryPort = parseDiscoveryPort(uri: &hostParsed[1])
            port = Int(hostParsed[1]) ?? 0
            discPort = discoveryPort ?? 0
        }

        return Node(id: id, host: host, port: port, discoveryPort: discPort)
    }

    private func correct(host: String) -> String {
        // check host contains only decimals and dot
        let isNumeric = host.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted.subtracting(CharacterSet(charactersIn: "."))) != nil
        let correctHost = isNumeric ? "" : host
        return correctHost
    }

    private func parseDiscoveryPort(uri: inout String) -> Int? {
        // split by discPort separator '?'
        let discPortParsed = uri.split(separator: "?")
        // if can't find any parameters just return nil and not change uri
        guard discPortParsed.count >= 2 else {
            return nil
        }
        // modify uri, drop all from '?'
        uri = String(discPortParsed[0])
        // get last parameter
        let portPart = discPortParsed.last!
        guard portPart.contains("discport=") else {
            return nil
        }

        return Int(String(portPart.dropFirst(9)))
    }

}

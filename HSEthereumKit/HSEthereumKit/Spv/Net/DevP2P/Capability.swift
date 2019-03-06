class Capability: Equatable {
    let name: String
    let version: Int
    let packetTypesMap: [Int: IMessage.Type]
    
    init(name: String, version: Int, packetTypesMap: [Int: IMessage.Type] = [:]) {
        self.name = name
        self.version = version
        self.packetTypesMap = packetTypesMap
    }

    func toArray() -> [Any] {
        return [name, version]
    }
    
    func toString() -> String {
        return "[name: \(name); version: \(version)]"
    }
    
    public static func == (lhs: Capability, rhs: Capability) -> Bool {
        return lhs.name == rhs.name && lhs.version == rhs.version
    }
    
}

public struct Token {
    public let symbol: String
    public let name: String
    public let decimals: Int
    public let address: String
    public let logoUri: String

    public init(symbol: String, name: String, decimals: Int, address: String, logoUri: String) {
        self.symbol = symbol
        self.name = name
        self.decimals = decimals
        self.address = address
        self.logoUri = logoUri
    }

}

extension Token: CustomStringConvertible {

    public var description: String {
        "[symbol: \(symbol); name: \(name); decimals: \(decimals.description); decimals: \(address)]"
    }

}

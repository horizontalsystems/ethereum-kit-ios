import EthereumKit

class SwapConverter {
    private let wethAddress: Data

    init(networkType: NetworkType) throws {
        self.wethAddress = try SwapConverter.wethAddress(networkType: networkType)
    }

    func token(swapItem: SwapItem) throws -> Token {
        switch swapItem {
        case .ethereum: return .eth(wethAddress: wethAddress)
        case .erc20(let contractAddress): return .erc20(address: try SwapConverter.convert(address: contractAddress))
        }
    }

    private static func convert(address: String) throws -> Data {
        guard let address = Data(hex: address) else {
            throw ConversionError.invalidAddress
        }

        return address
    }

    private static func wethAddress(networkType: NetworkType) throws -> Data {
        let address: String

        switch networkType {
        case .mainNet: address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        case .ropsten: address = "0xc778417E063141139Fce010982780140Aa0cD5Ab"
        case .kovan: address = "0xd0A1E359811322d97991E03f863a0C30C2cF029C"
        }

        return try convert(address: address)
    }

    public enum ConversionError: Error {
        case invalidAddress
    }

}

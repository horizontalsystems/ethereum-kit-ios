import EthereumKit

class TokenFactory {
    private let wethAddress: Address

    init(networkType: NetworkType) throws {
        wethAddress = try TokenFactory.wethAddress(networkType: networkType)
    }

    var etherToken: Token {
        .eth(wethAddress: wethAddress)
    }

    func token(contractAddress: Address, decimals: Int) -> Token {
        .erc20(address: contractAddress, decimals: decimals)
    }

}

extension TokenFactory {

    private static func wethAddress(networkType: NetworkType) throws -> Address {
        let wethAddressHex: String

        switch networkType {
        case .ethMainNet: wethAddressHex = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
        case .ropsten: wethAddressHex = "0xc778417E063141139Fce010982780140Aa0cD5Ab"
        case .kovan: wethAddressHex = "0xd0A1E359811322d97991E03f863a0C30C2cF029C"
        default: throw Kit.InitializationError.nonEthereumNetwork
        }

        return try Address(hex: wethAddressHex)
    }

}

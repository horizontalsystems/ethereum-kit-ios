import EthereumKit

class TokenFactory {
    private let wethAddress: Address

    init(network: Network) throws {
        wethAddress = try TokenFactory.wethAddress(network: network)
    }

    var etherToken: Token {
        .eth(wethAddress: wethAddress)
    }

    func token(contractAddress: Address, decimals: Int) -> Token {
        .erc20(address: contractAddress, decimals: decimals)
    }

}

extension TokenFactory {

    private static func wethAddress(network: Network) throws -> Address {
        let wethAddressHex: String

        switch network.chainId {
        case 1: wethAddressHex = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        case 56: wethAddressHex = "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"
        case 3, 4: wethAddressHex = "0xc778417E063141139Fce010982780140Aa0cD5Ab"
        case 42: wethAddressHex = "0xd0A1E359811322d97991E03f863a0C30C2cF029C"
        case 5: wethAddressHex = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
        default: throw UnsupportedChainError.noWethAddress
        }

        return try Address(hex: wethAddressHex)
    }

    enum UnsupportedChainError: Error {
        case noWethAddress
    }

}

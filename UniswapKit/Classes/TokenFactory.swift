import EthereumKit

class TokenFactory {
    private let wethAddress: Address

    init(chain: Chain) throws {
        wethAddress = try TokenFactory.wethAddress(chain: chain)
    }

    var etherToken: Token {
        .eth(wethAddress: wethAddress)
    }

    func token(contractAddress: Address, decimals: Int) -> Token {
        .erc20(address: contractAddress, decimals: decimals)
    }

}

extension TokenFactory {

    private static func wethAddress(chain: Chain) throws -> Address {
        let wethAddressHex: String

        switch chain.id {
        case 1: wethAddressHex = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        case 10: wethAddressHex = "0x4200000000000000000000000000000000000006"
        case 56: wethAddressHex = "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"
        case 137: wethAddressHex = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
        case 43114: wethAddressHex = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7"
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

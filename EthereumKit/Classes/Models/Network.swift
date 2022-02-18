import Foundation

public struct Network {
    public let chainId: Int
    public let coinType: UInt32
    public let blockTime: TimeInterval
    public let isEIP1559Supported: Bool
    public let explorer: Explorer

    public init(chainId: Int, coinType: UInt32, blockTime: TimeInterval, isEIP1559Supported: Bool, explorer: Explorer) {
        self.chainId = chainId
        self.coinType = coinType
        self.blockTime = blockTime
        self.isEIP1559Supported = isEIP1559Supported
        self.explorer = explorer
    }

    var isMainNet: Bool {
        coinType != 1
    }

}

extension Network {

    public enum Explorer {
        case etherscan(baseUrl: String, apiKey: String)
    }

}

extension Network {

    public static func ethereum(etherscanApiKey: String) -> Network {
        Network(
                chainId: 1,
                coinType: 60,
                blockTime: 15,
                isEIP1559Supported: true,
                explorer: .etherscan(baseUrl: "https://api.etherscan.io", apiKey: etherscanApiKey)
        )
    }

    public static func binanceSmartChain(etherscanApiKey: String) -> Network {
        Network(
                chainId: 56,
                coinType: 60, // actually Binance Smart Chain has coin type 9006
                blockTime: 5,
                isEIP1559Supported: false,
                explorer: .etherscan(baseUrl: "https://api.bscscan.com", apiKey: etherscanApiKey)
        )
    }

    public static func ethereumRopsten(etherscanApiKey: String) -> Network {
        Network(
                chainId: 3,
                coinType: 1,
                blockTime: 15,
                isEIP1559Supported: true,
                explorer: .etherscan(baseUrl: "https://api-ropsten.etherscan.io", apiKey: etherscanApiKey)
        )
    }

    public static func ethereumKovan(etherscanApiKey: String) -> Network {
        Network(
                chainId: 42,
                coinType: 1,
                blockTime: 4,
                isEIP1559Supported: true,
                explorer: .etherscan(baseUrl: "https://api-kovan.etherscan.io", apiKey: etherscanApiKey)
        )
    }

    public static func ethereumRinkeby(etherscanApiKey: String) -> Network {
        Network(
                chainId: 4,
                coinType: 1,
                blockTime: 15,
                isEIP1559Supported: true,
                explorer: .etherscan(baseUrl: "https://api-rinkeby.etherscan.io", apiKey: etherscanApiKey)
        )
    }

    public static func ethereumGoerly(etherscanApiKey: String) -> Network {
        Network(
                chainId: 5,
                coinType: 1,
                blockTime: 15,
                isEIP1559Supported: true,
                explorer: .etherscan(baseUrl: "https://api-goerli.etherscan.io", apiKey: etherscanApiKey)
        )
    }

}

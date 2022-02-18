import Foundation

public struct Network {
    public let chainId: Int
    public let coinType: UInt32
    public let blockTime: TimeInterval
    public let isEIP1559Supported: Bool

    public init(chainId: Int, coinType: UInt32, blockTime: TimeInterval, isEIP1559Supported: Bool) {
        self.chainId = chainId
        self.coinType = coinType
        self.blockTime = blockTime
        self.isEIP1559Supported = isEIP1559Supported
    }

    var isMainNet: Bool {
        coinType != 1
    }

}

extension Network {

    public static var ethereum: Network {
        Network(
                chainId: 1,
                coinType: 60,
                blockTime: 15,
                isEIP1559Supported: true
        )
    }

    public static var binanceSmartChain: Network {
        Network(
                chainId: 56,
                coinType: 60, // actually Binance Smart Chain has coin type 9006
                blockTime: 5,
                isEIP1559Supported: false
        )
    }

    public static var ethereumRopsten: Network {
        Network(
                chainId: 3,
                coinType: 1,
                blockTime: 15,
                isEIP1559Supported: true
        )
    }

    public static var ethereumKovan: Network {
        Network(
                chainId: 42,
                coinType: 1,
                blockTime: 4,
                isEIP1559Supported: true
        )
    }

    public static var ethereumRinkeby: Network {
        Network(
                chainId: 4,
                coinType: 1,
                blockTime: 15,
                isEIP1559Supported: true
        )
    }

    public static var ethereumGoerly: Network {
        Network(
                chainId: 5,
                coinType: 1,
                blockTime: 15,
                isEIP1559Supported: true
        )
    }

}

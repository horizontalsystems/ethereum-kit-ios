import EthereumKit
import HsToolKit

class Configuration {
    static let shared = Configuration()

    let syncMode: SyncMode = .api
    let networkType: NetworkType = .ropsten
    let minLogLevel: Logger.Level = .debug
    let defaultsWords = "apart approve black  comfort steel spin real renew tone primary key cherry"

    let infuraCredentials: (id: String, secret: String?) = (id: "2a1306f1d12f4c109a4d4fb9be46b02e", secret: "fc479a9290b64a84a15fa6544a130218")
    let etherscanApiKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"

    var erc20Tokens: [Erc20Token] {
        switch networkType {
        case .ethMainNet: return [
            Erc20Token(name: "DAI",       coin: "DAI",  contractAddress: try! Address(hex: "0x6b175474e89094c44da98b954eedeac495271d0f"), decimal: 18),
            Erc20Token(name: "USD Coin",  coin: "USDC", contractAddress: try! Address(hex: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"), decimal: 6),
        ]
        case .bscMainNet: return [
            Erc20Token(name: "Beefy.Finance", coin: "BIFI",  contractAddress: try! Address(hex: "0xCa3F508B8e4Dd382eE878A314789373D80A5190A"), decimal: 18),
            Erc20Token(name: "PancakeSwap", coin: "CAKE",  contractAddress: try! Address(hex: "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"), decimal: 18),
            Erc20Token(name: "BUSD",        coin: "BUSD",  contractAddress: try! Address(hex: "0xe9e7cea3dedca5984780bafc599bd69add087d56"), decimal: 18),
        ]
        case .ropsten: return [
            //            Erc20Token(name: "GMO coins", coin: "GMOLW", contractAddress: try! Address(hex: "0xbb74a24d83470f64d5f0c01688fbb49a5a251b32"), decimal: 18),
            Erc20Token(name: "DAI",       coin: "DAI",   contractAddress: try! Address(hex: "0xad6d458402f60fd3bd25163575031acdce07538d"), decimal: 18),
            //            Erc20Token(name: "MMM",       coin: "MMM",   contractAddress: try! Address(hex: "0x3e500c5f4de2738f65c90c6cc93b173792127481"), decimal: 8),
            //            Erc20Token(name: "WEENUS",    coin: "WEENUS", contractAddress: try! Address(hex: "0x101848d5c5bbca18e6b4431eedf6b95e9adf82fa"), decimal: 18),
        ]
        case .rinkeby: return []
        case .kovan: return [
            Erc20Token(name: "DAI",       coin: "DAI",   contractAddress: try! Address(hex: "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa"), decimal: 18),
        ]
        case .goerli: return []
        }
    }

}

public struct Erc20Token {
    let name: String
    let coin: String
    let contractAddress: Address
    let decimal: Int
}

extension Configuration {

    enum SyncMode {
        case api
        case spv
        case geth
    }

}

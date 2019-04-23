import EthereumKit

class Configuration {
    static let shared = Configuration()

    let syncMode: SyncMode = .api
    let networkType: EthereumKit.NetworkType = .ropsten

    let defaultsWords = "mom year father track attend frown loyal goddess crisp abandon juice roof"

    let infuraProjectId = "2a1306f1d12f4c109a4d4fb9be46b02e"
    let etherscanApiKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"

    let erc20Tokens = [
        Erc20Token(name: "ToxaCoin", coin: "TXC", contractAddress: "0xf559862f9265756619d5523bbc4bd8422898e97d", decimal: 18, balancePosition: 6),
        Erc20Token(name: "SuperPay", coin: "SPAY", contractAddress: "0x9ebca7b1ea057c0ffe9a59827bb954a4ea057521", decimal: 6, balancePosition: 3)
    ]

}

extension Configuration {

    struct Erc20Token {
        let name: String
        let coin: String
        let contractAddress: String
        let decimal: Int
        let balancePosition: Int
    }

    enum SyncMode {
        case api
        case spv
    }

}

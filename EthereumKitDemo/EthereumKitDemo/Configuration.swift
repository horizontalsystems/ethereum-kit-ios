import EthereumKit

class Configuration {
    static let shared = Configuration()

    let syncMode: SyncMode = .api
    let networkType: EthereumKit.NetworkType = .mainNet

    let defaultsWords = "mom year father track attend frown loyal goddess crisp abandon juice roof"

    let infuraProjectId = "2a1306f1d12f4c109a4d4fb9be46b02e"
    let etherscanApiKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"

    let erc20Tokens = [
//        Erc20Token(name: "Max Token", coin: "MXT", contractAddress: "0xf559862f9265756619d5523bbc4bd8422898e97d", decimal: 28, balancePosition: 6),
        Erc20Token(name: "Basic Attention Token", coin: "BAT", contractAddress: "0x0D8775F648430679A709E98d2b0Cb6250d2887EF", decimal: 18, balancePosition: 1),
        Erc20Token(name: "Dai", coin: "DAI", contractAddress: "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359", decimal: 18, balancePosition: 1),
        Erc20Token(name: "Huobi Token", coin: "HT", contractAddress: "0x6f259637dcD74C767781E37Bc6133cd6A68aa161", decimal: 18, balancePosition: 0),
        Erc20Token(name: "OmiseGO", coin: "OMG", contractAddress: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07", decimal: 18, balancePosition: 1),
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

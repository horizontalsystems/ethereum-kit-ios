import RxSwift
import EthereumKit
import Erc20Kit
import HdWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var ethereumKit: EthereumKit.Kit!

    var ethereumAdapter: EthereumAdapter!
    var erc20Adapters = [Erc20Adapter]()

    init() {
        if let words = savedWords {
            initEthereumKit(words: words)
        }
    }

    func login(words: [String]) {
        try! EthereumKit.Kit.clear(exceptFor: ["walletId"])
        try! Erc20Kit.Kit.clear(exceptFor: ["walletId"])

        save(words: words)
        initEthereumKit(words: words)
    }

    func logout() {
        clearWords()

        ethereumKit = nil
        ethereumAdapter = nil
        erc20Adapters = []
    }

    private func initEthereumKit(words: [String]) {
        let configuration = Configuration.shared

        let syncMode: WordsSyncMode

        switch configuration.syncMode {
        case .api: syncMode = .api
        case .spv: syncMode = .spv
        case .geth: syncMode = .geth
        }

        let ethereumKit = try! Kit.instance(
                words: words,
                syncMode: syncMode,
                networkType: configuration.networkType,
                infuraCredentials: configuration.infuraCredentials,
                etherscanApiKey: configuration.etherscanApiKey,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        ethereumAdapter = EthereumAdapter(ethereumKit: ethereumKit)

        for token in configuration.erc20Tokens {
            let adapter = Erc20Adapter(ethereumKit: ethereumKit, name: token.name, coin: token.coin, contractAddress: token.contractAddress, decimal: token.decimal)
            erc20Adapters.append(adapter)
        }

        self.ethereumKit = ethereumKit

        ethereumKit.start()
    }

    private var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

}

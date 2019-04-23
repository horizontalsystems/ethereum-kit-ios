import RxSwift
import EthereumKit
import Erc20Kit
import HSHDWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var ethereumKit: EthereumKit!
    var erc20Kit: Erc20Kit!

    var ethereumAdapter: EthereumAdapter!
    var erc20Adapters = [Erc20Adapter]()

    init() {
        if let words = savedWords {
            initEthereumKit(words: words)
        }
    }

    func login(words: [String]) {
        save(words: words)
        initEthereumKit(words: words)
    }

    func logout() {
        ethereumKit.clear()
        erc20Kit.clear()
        clearWords()

        ethereumKit = nil
        erc20Kit = nil

        ethereumAdapter = nil
        erc20Adapters = []
    }

    private func initEthereumKit(words: [String]) {
        let configuration = Configuration.shared

        let syncMode: EthereumKit.WordsSyncMode

        switch configuration.syncMode {
        case .api: syncMode = .api(infuraProjectId: configuration.infuraProjectId)
        case .spv: syncMode = .spv
        }

        let ethereumKit = try! EthereumKit.instance(
                words: words,
                syncMode: syncMode,
                networkType: configuration.networkType,
                etherscanApiKey: configuration.etherscanApiKey,
                minLogLevel: .verbose
        )

        let erc20Kit = Erc20Kit.instance(
                ethereumKit: ethereumKit,
                minLogLevel: .verbose
        )

        ethereumAdapter = EthereumAdapter(ethereumKit: ethereumKit)

        for token in configuration.erc20Tokens {
            let adapter = Erc20Adapter(ethereumKit: ethereumKit, erc20Kit: erc20Kit, name: token.name, coin: token.coin, contractAddress: token.contractAddress, balancePosition: token.balancePosition, decimal: token.decimal)
            erc20Adapters.append(adapter)
        }

        self.ethereumKit = ethereumKit
        self.erc20Kit = erc20Kit

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

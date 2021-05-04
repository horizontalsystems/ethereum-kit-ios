import RxSwift
import EthereumKit
import Erc20Kit
import UniswapKit
import HdWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var evmKit: EthereumKit.Kit!
    var uniswapKit: UniswapKit.Kit?

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

        evmKit = nil
        uniswapKit = nil
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

        let syncSource: SyncSource

        if case .bscMainNet = configuration.networkType {
            syncSource = Kit.defaultBscWebsocketSyncSource()!
        } else {
//            syncSource = Kit.infuraWebsocketSyncSource(networkType: configuration.networkType, projectId: configuration.infuraCredentials.id, projectSecret: configuration.infuraCredentials.secret)!
            syncSource = Kit.infuraHttpSyncSource(networkType: configuration.networkType, projectId: configuration.infuraCredentials.id, projectSecret: configuration.infuraCredentials.secret)!
        }

        let seed = Mnemonic.seed(mnemonic: words)

        let evmKit = try! Kit.instance(
                seed: seed,
                networkType: configuration.networkType,
                syncSource: syncSource,
                etherscanApiKey: configuration.etherscanApiKey,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        uniswapKit = try? UniswapKit.Kit.instance(evmKit: evmKit)

        ethereumAdapter = EthereumAdapter(ethereumKit: evmKit)

        for token in configuration.erc20Tokens {
            let adapter = Erc20Adapter(ethereumKit: evmKit, token: token)
            erc20Adapters.append(adapter)
        }

        self.evmKit = evmKit
        evmKit.add(decorator: Erc20Kit.Kit.getDecorator())
        evmKit.add(decorator: UniswapKit.Kit.getDecorator())
        evmKit.add(transactionSyncer: Erc20Kit.Kit.getTransactionSyncer(evmKit: evmKit))

        evmKit.start()

        for adapter in erc20Adapters {
            adapter.start()
        }
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

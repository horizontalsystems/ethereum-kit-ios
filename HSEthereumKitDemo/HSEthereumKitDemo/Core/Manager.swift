import RxSwift
import HSEthereumKit
import HSHDWalletKit

class Manager {
    private let infuraProjectId = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private let etherscanApiKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"
    private let contractAddress = "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367"
    private let contractDecimal = 18

    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var ethereumKit: EthereumKit!
    var ethereumAdapter: EthereumAdapter!
    var erc20Adapter: Erc20Adapter!

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
        clearWords()
        ethereumKit = nil
        ethereumAdapter = nil
        erc20Adapter = nil
    }

    private func initEthereumKit(words: [String]) {
//        let nodePrivateKey = try! hdWallet.privateKey(account: 100, index: 100, chain: .external).raw
//        ethereumKit = EthereumKit.instance(privateKey: privateKey, syncMode: .spv(nodePrivateKey: nodePrivateKey), networkType: networkType)

        ethereumKit = try! EthereumKit.instance(words: words, syncMode: .api(infuraProjectId: infuraProjectId, etherscanApiKey: etherscanApiKey), networkType: .ropsten, minLogLevel: .verbose)

        ethereumAdapter = EthereumAdapter(ethereumKit: ethereumKit)
        erc20Adapter = Erc20Adapter(ethereumKit: ethereumKit, contractAddress: contractAddress, decimal: contractDecimal)

//        ethereumKit.start()
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

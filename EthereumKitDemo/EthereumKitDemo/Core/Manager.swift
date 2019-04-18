import RxSwift
import EthereumKit
import Erc20Kit
import HSHDWalletKit

class Manager {
    private let infuraProjectId = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private let etherscanApiKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"
    private let tokenContractAddress = "0xf559862f9265756619d5523bbc4bd8422898e97d"
    private let tokenDecimal = 18
    private let tokenBalanceStoragePosition = 6

    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var ethereumKit: EthereumKit!
    var erc20Kit: Erc20Kit!
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
        erc20Kit = nil
        ethereumAdapter = nil
        erc20Adapter = nil
    }

    private func initEthereumKit(words: [String]) {
//        let nodePrivateKey = try! hdWallet.privateKey(account: 100, index: 100, chain: .external).raw
//        ethereumKit = EthereumKit.instance(privateKey: privateKey, syncMode: .spv(nodePrivateKey: nodePrivateKey), etherscanApiKey: etherscanApiKey, networkType: networkType)

        let ethereumKit = try! EthereumKit.instance(words: words, syncMode: .api(infuraProjectId: infuraProjectId), networkType: .ropsten, etherscanApiKey: etherscanApiKey, minLogLevel: .verbose)
        let erc20Kit = Erc20Kit.instance(ethereumKit: ethereumKit, networkType: .ropsten, etherscanApiKey: etherscanApiKey)

        ethereumAdapter = EthereumAdapter(ethereumKit: ethereumKit)
        erc20Adapter = Erc20Adapter(erc20Kit: erc20Kit, ethereumKit: ethereumKit, contractAddress: tokenContractAddress, position: tokenBalanceStoragePosition, decimal: tokenDecimal)

        self.ethereumKit = ethereumKit
        self.erc20Kit = erc20Kit

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

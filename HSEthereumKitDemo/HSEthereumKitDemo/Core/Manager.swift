import Foundation
import RxSwift
import HSEthereumKit

class Manager {
    private let infuraKey = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private let etherscanKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"
    private let contractAddress = "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367"
    private let contractDecimal = 18
    private let testMode = true

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
        ethereumKit = try! EthereumKit.ethereumKit(words: words, walletId: "SomeId", testMode: testMode, infuraKey: infuraKey, etherscanKey: etherscanKey)

        ethereumAdapter = EthereumAdapter(ethereumKit: ethereumKit)
        erc20Adapter = Erc20Adapter(ethereumKit: ethereumKit, contractAddress: contractAddress, decimal: contractDecimal)

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

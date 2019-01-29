import Foundation
import RealmSwift
import RxSwift
import HSEthereumKit

class Manager {
    private static let infuraKey = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private static let etherscanKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"
    public static let contractAddress = "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367"
    public static let contractDecimal = 18 // 28
//    public static let contractAddress = "0xF559862f9265756619d5523bBC4bd8422898e97d"
//    public static let contractDecimal = 28

    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    let coin: EthereumKit.Coin = .ethereum(network: .testNet)

    var ethereumKit: EthereumKit!

    let balanceSubject = PublishSubject<(address: String, balance: Decimal)>()
    let transactionsSubject = PublishSubject<Void>()
    let progressSubject = PublishSubject<EthereumKit.KitState>()

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
        do {
            try ethereumKit.clear()
        } catch {
            print("EthereumKit Clear Error: \(error)")
        }

        clearWords()
        ethereumKit = nil
    }

    private func initEthereumKit(words: [String]) {
        ethereumKit = EthereumKit(withWords: words, coin: coin, infuraKey: Manager.infuraKey, etherscanKey: Manager.etherscanKey, debugPrints: false)
        ethereumKit.enable(contractAddress: Manager.contractAddress, decimal: Manager.contractDecimal)
        ethereumKit.delegate = self
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

extension Manager: EthereumKitDelegate {

    public func transactionsUpdated(ethereumKit: EthereumKit, inserted: [EthereumTransaction], updated: [EthereumTransaction], deleted: [Int]) {
        transactionsSubject.onNext(())
    }

    public func balanceUpdated(ethereumKit: EthereumKit, address: String, balance: Decimal) {
        balanceSubject.onNext((address: address, balance: balance))
    }

    public func kitStateUpdated(address: String?, state: EthereumKit.KitState) {
        progressSubject.onNext(state)
    }

}

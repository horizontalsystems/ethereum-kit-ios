import Foundation
import RealmSwift
import RxSwift
import HSEthereumKit

class Manager {
    private static let infuraKey = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private static let etherscanKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"

    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    let coin: EthereumKit.Coin = .ethereum(network: .testNet)

    var ethereumKit: EthereumKit!

    let balanceSubject = PublishSubject<BInt>()
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

    public func balanceUpdated(ethereumKit: EthereumKit, balance: BInt) {
        balanceSubject.onNext(balance)
    }

    public func kitStateUpdated(state: EthereumKit.KitState) {
        progressSubject.onNext(state)
    }

}

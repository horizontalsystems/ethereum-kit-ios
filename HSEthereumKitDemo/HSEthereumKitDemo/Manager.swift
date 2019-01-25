import Foundation
import RealmSwift
import RxSwift
import HSEthereumKit

class Manager {
    private static let infuraKey = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private static let etherscanKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"

    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    let coin: EthereumKit.Coin = .ethereum(network: .testNet) //.erc20(network: .testNet, address: "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367", decimal: 18)

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
        ethereumKit.enable(contractAddress: "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367", decimal: 18)
//        ethereumKit.enable(contract: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52", decimal: 18)
//        ethereumKit.enable(contract: "0xd850942ef8811f2a866692a623011bde52a462c1", decimal: 18)
//        ethereumKit.enable(contract: "0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750", decimal: 8)
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

    public func balanceUpdated(ethereumKit: EthereumKit, inserted: [EthereumBalance], updated: [EthereumBalance], deleted: [Int]) {
        inserted.forEach { balance in
            balanceSubject.onNext((address: balance.address, balance: ethereumKit.erc20Balance[balance.address] ?? 0))
        }
        updated.forEach { balance in
            balanceSubject.onNext((address: balance.address, balance: ethereumKit.erc20Balance[balance.address] ?? 0))
        }
    }

    public func kitStateUpdated(state: EthereumKit.KitState) {
        progressSubject.onNext(state)
    }

}

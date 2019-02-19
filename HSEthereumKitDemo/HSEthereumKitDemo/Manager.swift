import Foundation
import RxSwift
import HSEthereumKit

class Manager {
    private static let infuraKey = "2a1306f1d12f4c109a4d4fb9be46b02e"
    private static let etherscanKey = "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE"
    public static let contractAddress = "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367"
    public static let contractDecimal = 18
//    public static let contractAddress = "0xF559862f9265756619d5523bBC4bd8422898e97d"
//    public static let contractDecimal = 28

    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    private let testMode = true

    var ethereumKit: EthereumKit!
    var erc20Adapter = Erc20Adapter()

    let balanceSubject = PublishSubject<Void>()
    let lastBlockHeight = PublishSubject<Void>()
    let transactionsSubject = PublishSubject<Void>()
    let syncStateSubject = PublishSubject<Void>()

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
    }

    private func initEthereumKit(words: [String]) {
        ethereumKit = try! EthereumKit.ethereumKit(words: words, walletId: "SomeId", testMode: testMode, infuraKey: Manager.infuraKey, etherscanKey: Manager.etherscanKey, debugPrints: false)
        ethereumKit.delegate = self

        ethereumKit.register(contractAddress: Manager.contractAddress, decimal: Manager.contractDecimal, delegate: erc20Adapter)
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

extension Manager: IEthereumKitDelegate {

    public func onUpdate(transactions: [EthereumTransaction]) {
        transactionsSubject.onNext(())
    }

    public func onUpdateBalance() {
        balanceSubject.onNext(())
    }

    public func onUpdateLastBlockHeight() {
        lastBlockHeight.onNext(())
    }

    public func onUpdateSyncState() {
        syncStateSubject.onNext(())
    }

}

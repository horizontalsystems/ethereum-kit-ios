import RxSwift
import EthereumKit
import Erc20Kit
import NftKit
import UniswapKit
import OneInchKit
import HdWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"
    private let keyAddress = "address"

    var signer: EthereumKit.Signer!
    var evmKit: EthereumKit.Kit!
    var nftKit: NftKit.Kit!
    var uniswapKit: UniswapKit.Kit?
    var oneInchKit: OneInchKit.Kit?

    var ethereumAdapter: IAdapter!
    var erc20Adapters = [IAdapter]()
    var erc20Tokens = [String: String]()

    init() {
        if let words = savedWords {
            initEthereumKit(words: words)
        }
    }

    func login(words: [String]) {
        try! EthereumKit.Kit.clear(exceptFor: ["walletId"])
        try! NftKit.Kit.clear(exceptFor: ["walletId"])

        save(words: words)
        initEthereumKit(words: words)
    }

    func watch(address: Address) {
        try! EthereumKit.Kit.clear(exceptFor: ["walletId"])
        try! NftKit.Kit.clear(exceptFor: ["walletId"])

        save(address: address.hex)
        initEthereumKit(address: address)
    }

    func logout() {
        clearWords()

        signer = nil
        evmKit = nil
        nftKit = nil
        uniswapKit = nil
        oneInchKit = nil
        ethereumAdapter = nil
        erc20Adapters = []
    }

    private func initEthereumKit(words: [String]) {
        let configuration = Configuration.shared

        let seed = Mnemonic.seed(mnemonic: words)

        let signer = try! Signer.instance(
                seed: seed,
                chain: configuration.chain
        )
        let evmKit = try! EthereumKit.Kit.instance(
                address: Signer.address(seed: seed, chain: configuration.chain),
                chain: configuration.chain,
                rpcSource: configuration.rpcSource,
                transactionSource: configuration.transactionSource,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        nftKit = try! NftKit.Kit.instance(evmKit: evmKit)

        uniswapKit = try! UniswapKit.Kit.instance(evmKit: evmKit)
        oneInchKit = try! OneInchKit.Kit.instance(evmKit: evmKit)

        ethereumAdapter = EthereumAdapter(signer: signer, ethereumKit: evmKit)

        for token in configuration.erc20Tokens {
            let adapter = Erc20Adapter(signer: signer, ethereumKit: evmKit, token: token)
            erc20Adapters.append(adapter)
            erc20Tokens[token.contractAddress.eip55] = token.coin
        }

        self.signer = signer
        self.evmKit = evmKit

        Erc20Kit.Kit.addDecorators(to: evmKit)
        Erc20Kit.Kit.addTransactionSyncer(to: evmKit)

        nftKit.addEip721TransactionSyncer()
        nftKit.addEip1155TransactionSyncer()
        nftKit.addEip721Decorators()
        nftKit.addEip1155Decorators()

        UniswapKit.Kit.addDecorators(to: evmKit)

        OneInchKit.Kit.addDecorators(to: evmKit)

        evmKit.start()
        nftKit.sync()

        for adapter in erc20Adapters {
            adapter.start()
        }
    }

    private func initEthereumKit(address: Address) {
        let configuration = Configuration.shared

        let evmKit = try! Kit.instance(address: address,
                chain: configuration.chain,
                rpcSource: configuration.rpcSource,
                transactionSource: configuration.transactionSource,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        nftKit = try! NftKit.Kit.instance(evmKit: evmKit)

        uniswapKit = try! UniswapKit.Kit.instance(evmKit: evmKit)
        oneInchKit = try! OneInchKit.Kit.instance(evmKit: evmKit)

        ethereumAdapter = EthereumBaseAdapter(ethereumKit: evmKit)

        for token in configuration.erc20Tokens {
            let adapter = Erc20BaseAdapter(ethereumKit: evmKit, token: token)
            erc20Adapters.append(adapter)
            erc20Tokens[token.contractAddress.eip55] = token.coin
        }

        self.evmKit = evmKit

        Erc20Kit.Kit.addDecorators(to: evmKit)
        Erc20Kit.Kit.addTransactionSyncer(to: evmKit)

        nftKit.addEip721TransactionSyncer()
        nftKit.addEip1155TransactionSyncer()
        nftKit.addEip721Decorators()
        nftKit.addEip1155Decorators()

        UniswapKit.Kit.addDecorators(to: evmKit)

        OneInchKit.Kit.addDecorators(to: evmKit)

        evmKit.start()
        nftKit.sync()

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

    private func save(address: String) {
        UserDefaults.standard.set(address, forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

    private func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

}

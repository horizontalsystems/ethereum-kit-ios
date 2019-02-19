import RxSwift
import HSHDWalletKit

class GethBlockchain {
    private static let ethDecimal = 18
    private static let ethRate: Decimal = pow(10, ethDecimal)

    static let ethGasLimit = 21_000
    static let erc20GasLimit = 100_000
    static let defaultGasPrice: Decimal = 10_000_000_000 / ethRate

    private var disposeBag = DisposeBag()

    weak var delegate: IBlockchainDelegate?

    private let storage: IStorage
    private let hdWallet: Wallet

    private let geth: Geth
    private let gethProvider: IGethProviderProtocol

    private var erc20Contracts = [Erc20Contract]()

    let ethereumAddress: String
    let gasPrice: Decimal = 0

    init(storage: IStorage, words: [String], testMode: Bool, infuraKey: String, etherscanKey: String, debugPrints: Bool = false) throws {
        self.storage = storage

        let network: Network = testMode ? .ropsten : .mainnet

        hdWallet = try Wallet(seed: Mnemonic.seed(mnemonic: words), network: network, debugPrints: debugPrints)
        ethereumAddress = hdWallet.address()

        let configuration = Configuration(
                network: network,
                nodeEndpoint: network.infura + infuraKey,
                etherscanAPIKey: etherscanKey,
                debugPrints: debugPrints
        )
        geth = Geth(configuration: configuration)
        gethProvider = GethProvider(geth: geth)

    }

    private func refreshAll() {
        changeAllStates(state: .syncing)

        Single.zip(
                        gethProvider.getLastBlockHeight(),
                        gethProvider.getGasPrice(),
                        gethProvider.getBalance(address: ethereumAddress, blockParameter: .latest)
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] lastBlockHeight, gasPrice, balance in
                    self?.update(lastBlockHeight: lastBlockHeight)
                    self?.update(gasPrice: gasPrice)
                    self?.update(balance: balance)

                    self?.refreshTransactions()
                }, onError: { [weak self] _ in
                    self?.changeAllStates(state: .notSynced)
                })
                .disposed(by: disposeBag)

    }

    private func refreshTransactions() {
        let lastTransactionBlockHeight = storage.lastTransactionBlockHeight(erc20: false) ?? 0

        gethProvider.getTransactions(address: ethereumAddress, startBlock: Int64(lastTransactionBlockHeight + 1), rate: GethBlockchain.ethRate)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.update(transactions: transactions)
                    self?.delegate?.onUpdate(syncState: .synced)
                }, onError: { [weak self] _ in
                    self?.delegate?.onUpdate(syncState: .notSynced)
                })
                .disposed(by: disposeBag)

        guard !erc20Contracts.isEmpty else {
            return
        }

        let erc20LastTransactionBlockHeight = storage.lastTransactionBlockHeight(erc20: true) ?? 0

        gethProvider.getTransactionsErc20(address: ethereumAddress, startBlock: Int64(erc20LastTransactionBlockHeight + 1), contracts: erc20Contracts)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.updateErc20(transactions: transactions)
                    self?.refreshErc20Balances()
                }, onError: { [weak self] _ in
                    self?.erc20Contracts.forEach {
                        self?.delegate?.onUpdateErc20(syncState: .notSynced, contractAddress: $0.address)
                    }
                })
                .disposed(by: disposeBag)
    }

    private func refreshErc20Balances() {
        erc20Contracts.forEach { contract in
            gethProvider.getBalanceErc20(address: ethereumAddress, contractAddress: contract.address, decimal: contract.decimal, blockParameter: .latest)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { [weak self] balance in
                        self?.updateErc20(balance: balance, contractAddress: contract.address)
                        self?.delegate?.onUpdateErc20(syncState: .synced, contractAddress: contract.address)
                    }, onError: { [weak self] _ in
                        self?.delegate?.onUpdateErc20(syncState: .notSynced, contractAddress: contract.address)
                    })
                    .disposed(by: disposeBag)
        }
    }

    private func changeAllStates(state: EthereumKit.SyncState) {
        delegate?.onUpdate(syncState: state)
        erc20Contracts.forEach {
            delegate?.onUpdateErc20(syncState: state, contractAddress: $0.address)
        }
    }

    private func update(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    private func update(gasPrice: Decimal) {
        storage.save(gasPrice: gasPrice)
//        delegate?.onUpdate(gasPrice: gasPrice)
    }

    private func update(balance: Decimal) {
        storage.save(balance: balance, address: ethereumAddress)
        delegate?.onUpdate(balance: balance)
    }

    private func updateErc20(balance: Decimal, contractAddress: String) {
        storage.save(balance: balance, address: contractAddress)
        delegate?.onUpdateErc20(balance: balance, contractAddress: contractAddress)
    }

    private func update(transactions: [EthereumTransaction]) {
        storage.save(transactions: transactions)
        delegate?.onUpdate(transactions: transactions)
    }

    private func updateErc20(transactions: [EthereumTransaction]) {
        storage.save(transactions: transactions)

        var contractTransactions = [String: [EthereumTransaction]]()

        transactions.forEach { transaction in
            if let contractAddress = transaction.contractAddress {
                if contractTransactions[contractAddress] == nil {
                    contractTransactions[contractAddress] = []
                }
                contractTransactions[contractAddress]?.append(transaction)
            }
        }

        for (contractAddress, transactions) in contractTransactions {
            delegate?.onUpdateErc20(transactions: transactions, contractAddress: contractAddress)
        }
    }

    private func send(nonce: Int, address: String, value: Decimal, gasPrice: Decimal, completion: ((Error?) -> ())? = nil) throws {
        let wei = try Converter.toWei(ether: value)
        let gasPriceWei = try Converter.toWei(ether: gasPrice)

        let gasLimit = GethBlockchain.ethGasLimit
        let ethereumAddress = self.ethereumAddress

        // todo: remove !
        let rawTransaction = RawTransaction(wei: wei.asString(withBase: 10), to: address, gasPrice: gasPriceWei.toInt()!, gasLimit: gasLimit, nonce: nonce)

        let signedTransaction = try hdWallet.sign(rawTransaction: rawTransaction)

        geth.sendRawTransaction(rawTransaction: signedTransaction) { [weak self] result in
            switch result {
            case .success(let sentTransaction):
                let transaction = EthereumTransaction(hash: sentTransaction.id, nonce: nonce, from: ethereumAddress, to: address, value: value, gasLimit: gasLimit, gasPrice: gasPrice)
                self?.storage.save(transactions: [transaction])
                completion?(nil)
            case .failure(let error):
                completion?(error)
            }
        }
    }

}

extension GethBlockchain: IBlockchain {

    func start() {
        // todo: check reachability and decide if reachability should be in this layer

        refreshAll()
    }

    func stop() {
        disposeBag = DisposeBag()
    }

    func clear() {
        erc20Contracts = []
        disposeBag = DisposeBag()
    }

    func register(contractAddress: String, decimal: Int) {
        guard !erc20Contracts.contains(where: { $0.address == contractAddress }) else {
            return
        }

        erc20Contracts.append(Erc20Contract(address: contractAddress, decimal: decimal))

        // todo: refresh if not already refreshing

    }

    func unregister(contractAddress: String) {
        if let index = erc20Contracts.firstIndex(where: { $0.address == contractAddress }) {
            erc20Contracts.remove(at: index)
        }
    }

    func send(to address: String, amount: Decimal, gasPrice: Decimal?, onSuccess: (() -> ())?, onError: ((Error) -> ())?) {
        geth.getTransactionCount(of: ethereumAddress, blockParameter: .pending) { [weak self] result in
            switch result {
            case .success(let nonce):
                do {
//                    try self?.send(nonce: nonce, address: address, value: amount, gasPrice: gasPrice, completion: completion)
//                    onSuccess()
                } catch {
                    onError?(error)
                }
            case .failure(let error):
                onError?(error)
            }
        }
    }

    func erc20Send(to address: String, contractAddress: String, amount: Decimal, gasPrice: Decimal?, onSuccess: (() -> ())?, onError: ((Error) -> ())?) {
        // todo: implement erc20 send
    }

}

extension GethBlockchain {

    struct Erc20Contract: Equatable {
        let address: String
        let decimal: Int
    }

}

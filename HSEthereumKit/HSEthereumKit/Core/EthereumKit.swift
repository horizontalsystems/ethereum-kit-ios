import Foundation
import RealmSwift
import RxSwift

public class EthereumKit {
    let disposeBag = DisposeBag()

//    public weak var delegate: BitcoinKitDelegate?

    let network: Network
    let hdWallet: HDWallet

    public init(withWords words: [String], network: Network) {
        self.network = network
//        let wordsHash = words.joined()
//        let realmFileName = "\(wordsHash)-\(network).realm"

//        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//        let realmConfiguration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))

//        realmFactory = RealmFactory(configuration: realmConfiguration)

        do {
            hdWallet = HDWallet(seed: try Mnemonic.createSeed(mnemonic: words), network: network)
        } catch {
            fatalError("Can't create hdWallet")
        }

//        let realm = realmFactory.realm
//        let pubKeys = realm.objects(PublicKey.self)
    }

//    public func showRealmInfo() {
//        let realm = realmFactory.realm
//
//        let blocks = realm.objects(Block.self).sorted(byKeyPath: "height")
//        let syncedBlocks = blocks.filter("synced = %@", true)
//        let pubKeys = realm.objects(PublicKey.self)
//
//        for pubKey in pubKeys {
//            print("\(pubKey.index) --- \(pubKey.external) --- \(pubKey.keyHash.hex) --- \(addressConverter.convertToLegacy(keyHash: pubKey.keyHash, version: network.pubKeyHash, addressType: .pubKeyHash).stringValue) --- \(try! addressConverter.convert(keyHash: pubKey.keyHash, type: .p2wpkh).stringValue)")
//        }
//        print("PUBLIC KEYS COUNT: \(pubKeys.count)")
//
//        print("BLOCK COUNT: \(blocks.count) --- \(syncedBlocks.count) synced")
//        if let block = syncedBlocks.first {
//            print("First Synced Block: \(block.height) --- \(block.reversedHeaderHashHex)")
//        }
//        if let block = syncedBlocks.last {
//            print("Last Synced Block: \(block.height) --- \(block.reversedHeaderHashHex)")
//        }
//    }

    public func start() throws {
//        try initialSyncer.sync()
    }

    public func clear() throws {
//        let realm = realmFactory.realm

//        try realm.write {
//            realm.deleteAll()
//        }
    }

//    public var transactions: [TransactionInfo] {
//        return transactionRealmResults.map { transactionInfo(fromTransaction: $0) }
//    }

//    public var lastBlockInfo: BlockInfo? {
//        return blockRealmResults.last.map { blockInfo(fromBlock: $0) }
//    }

    public var balance: Int {
        var balance = 0

//        for output in unspentOutputRealmResults {
//            balance += output.value
//        }

        return balance
    }

    public func send(to address: String, value: Int) throws {
//        try transactionCreator.create(to: address, value: value)
    }

    public func validate(address: String) throws {
//        _ = try addressConverter.convert(address: address)
    }

    public func fee(for value: Int, toAddress: String? = nil, senderPay: Bool) throws -> Int {
        return 0
//        return try transactionBuilder.fee(for: value, feeRate: transactionCreator.feeRate, senderPay: true, address: toAddress)
    }

    public var receiveAddress: String {
        return "test-string"
//        return (try? addressManager.receiveAddress()) ?? ""
    }

    public var progress: Double {
        return 0
//        return progressSyncer.progress
    }

//    private func handleTransactions(changeset: RealmCollectionChange<Results<Transaction>>) {
//        if case let .update(collection, deletions, insertions, modifications) = changeset {
//            delegate?.transactionsUpdated(
//                    walletKit: self,
//                    inserted: insertions.map { collection[$0] }.map { transactionInfo(fromTransaction: $0) },
//                    updated: modifications.map { collection[$0] }.map { transactionInfo(fromTransaction: $0) },
//                    deleted: deletions
//            )
//        }
//    }
//
//    private func handleBlocks(changeset: RealmCollectionChange<Results<Block>>) {
//        if case let .update(collection, deletions, insertions, _) = changeset, let block = collection.last, (!deletions.isEmpty || !insertions.isEmpty) {
//            delegate?.lastBlockInfoUpdated(walletKit: self, lastBlockInfo: blockInfo(fromBlock: block))
//        }
//    }
//
//    private func handleUnspentOutputs(changeset: RealmCollectionChange<Results<TransactionOutput>>) {
//        if case .update = changeset {
//            delegate?.balanceUpdated(walletKit: self, balance: balance)
//        }
//    }

//    private func handleProgressUpdate(progress: Double) {
//        delegate?.progressUpdated(walletKit: self, progress: progress)
//    }

//    private var unspentOutputRealmResults: Results<TransactionOutput> {
//        return realmFactory.realm.objects(TransactionOutput.self)
//                .filter("publicKey != nil")
//                .filter("scriptType != %@", ScriptType.unknown.rawValue)
//                .filter("inputs.@count = %@", 0)
//    }

//    private var transactionRealmResults: Results<Transaction> {
//        return realmFactory.realm.objects(Transaction.self).filter("isMine = %@", true).sorted(byKeyPath: "block.height", ascending: false)
//    }
//
//    private var blockRealmResults: Results<Block> {
//        return realmFactory.realm.objects(Block.self).filter("synced = %@", true).sorted(byKeyPath: "height")
//    }

//    private func transactionInfo(fromTransaction transaction: Transaction) -> TransactionInfo {
//        var totalMineInput: Int = 0
//        var totalMineOutput: Int = 0
//        var fromAddresses = [TransactionAddress]()
//        var toAddresses = [TransactionAddress]()
//
//        for input in transaction.inputs {
//            if let previousOutput = input.previousOutput {
//                if previousOutput.publicKey != nil {
//                    totalMineInput += previousOutput.value
//                }
//            }
//
//            let mine = input.previousOutput?.publicKey != nil
//
//            if let address = input.address {
//                fromAddresses.append(TransactionAddress(address: address, mine: mine))
//            }
//        }
//
//        for output in transaction.outputs {
//            var mine = false
//
//            if output.publicKey != nil {
//                totalMineOutput += output.value
//                mine = true
//            }
//
//            if let address = output.address {
//                toAddresses.append(TransactionAddress(address: address, mine: mine))
//            }
//        }
//
//        let amount = totalMineOutput - totalMineInput
//
//        return TransactionInfo(
//                transactionHash: transaction.reversedHashHex,
//                from: fromAddresses,
//                to: toAddresses,
//                amount: amount,
//                blockHeight: transaction.block?.height,
//                timestamp: transaction.block?.header?.timestamp
//        )
//    }
//
//    private func blockInfo(fromBlock block: Block) -> BlockInfo {
//        return BlockInfo(
//                headerHash: block.reversedHeaderHashHex,
//                height: block.height,
//                timestamp: block.header?.timestamp
//        )
//    }

}

public protocol BitcoinKitDelegate: class {
//    func transactionsUpdated(walletKit: WalletKit, inserted: [TransactionInfo], updated: [TransactionInfo], deleted: [Int])
//    func balanceUpdated(walletKit: WalletKit, balance: Int)
//    func lastBlockInfoUpdated(walletKit: WalletKit, lastBlockInfo: BlockInfo)
//    func progressUpdated(walletKit: WalletKit, progress: Double)
}

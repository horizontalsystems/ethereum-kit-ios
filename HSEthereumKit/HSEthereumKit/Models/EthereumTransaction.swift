import Foundation
import RealmSwift

public class EthereumTransaction: Object {
    @objc public dynamic var blockHash: String = ""
    @objc public dynamic var blockNumber: Int = 0
    @objc public dynamic var txHash: String = ""
    @objc public dynamic var input: String = ""
    @objc public dynamic var confirmations: Int = 0
    @objc public dynamic var nonce: Int = 0
    @objc public dynamic var timestamp: Int = 0
    @objc public dynamic var contractAddress: String = ""
    @objc public dynamic var from: String = ""
    @objc public dynamic var to: String = ""
    @objc public dynamic var gas: Int = 0
    @objc public dynamic var gasPrice: Int = 0
    @objc public dynamic var gasUsed: String = ""
    @objc public dynamic var cumulativeGasUsed: String = ""
    @objc public dynamic var isError: String = ""
    @objc public dynamic var transactionIndex: String = ""
    @objc public dynamic var txReceiptStatus: String = ""
    @objc public dynamic var value: String = ""

    override public class func primaryKey() -> String? {
        return "txHash"
    }

    public convenience init(txHash: String, from: String, to: String, contractAddress: String? = nil, gas: Int, gasPrice: Int, value: String, timestamp: Int) {
        self.init()
        self.txHash = txHash

        self.from = from
        self.to = to
        if let contractAddress = contractAddress {
            self.contractAddress = contractAddress
        }
        self.gas = gas
        self.gasPrice = gasPrice
        self.value = value
        self.timestamp = timestamp
    }

    public convenience init(transaction: Transaction) {
        self.init()
        self.txHash = transaction.hash
        update(with: transaction)
    }

    public func update(with transaction: Transaction) {
        self.blockHash = transaction.blockHash
        self.blockNumber = Int(transaction.blockNumber) ?? 0
        self.input = transaction.input
        self.confirmations = Int(transaction.confirmations) ?? 0
        self.nonce = Int(transaction.nonce) ?? 0
        self.timestamp = Int(transaction.timeStamp) ?? 0
        self.contractAddress = transaction.contractAddress
        self.from = transaction.from
        self.to = transaction.to
        self.gas = Int(transaction.gas) ?? 0
        self.gasPrice = Int(transaction.gasPrice) ?? 0
        self.gasUsed = transaction.gasUsed
        self.cumulativeGasUsed = transaction.cumulativeGasUsed
        self.isError = transaction.isError ?? ""
        self.transactionIndex = transaction.transactionIndex
        self.txReceiptStatus = transaction.txReceiptStatus
        self.value = transaction.value
    }

}

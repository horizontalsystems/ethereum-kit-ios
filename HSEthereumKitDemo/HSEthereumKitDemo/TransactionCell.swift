import UIKit
import HSEthereumKit

class TransactionCell: UITableViewCell {

    @IBOutlet weak var infoLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func bind(transaction: EthereumTransaction, index: Int, lastBlockHeight: Int) {
        let fromAddress = transaction.from
        let toAddress = transaction.to

        let amount = transaction.value
        var confirmations = ""

        if let blockNumber = transaction.blockNumber {
            confirmations = blockNumber > 0 ? "Confirmations: \(lastBlockHeight - blockNumber)" : ""
        }

        infoLabel?.text =
                "# \(index)\n" +
                "Amount: \(amount)\n" +
                "Date: \(transaction.timestamp)\n" +
                "Tx Hash: \(transaction.hash.prefix(10))...\n" +
                "From: \(fromAddress)\n" +
                "To: \(toAddress)\n" + 
                        (transaction.contractAddress == nil ? "" : "Contract: \(transaction.contractAddress!) \n") +
                confirmations
    }

}

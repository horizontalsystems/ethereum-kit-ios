import UIKit
import HSEthereumKit

class TransactionCell: UITableViewCell {

    @IBOutlet weak var infoLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func bind(transaction: EthereumTransaction, lastBlockHeight: Int) {
        let fromAddress = transaction.from
        let toAddress = transaction.to

        let amount = transaction.value

        infoLabel?.text =
                "Amount: \(amount)\n" +
                "Date: \(transaction.timestamp)\n" +
                "Tx Hash: \(transaction.txHash.prefix(10))...\n" +
                "From: \(fromAddress)\n" +
                "To: \(toAddress)\n" +
                "Confirmations: \(transaction.confirmations)"
    }

}

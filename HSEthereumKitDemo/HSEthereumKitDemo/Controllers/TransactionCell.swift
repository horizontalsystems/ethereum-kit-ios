import UIKit

class TransactionCell: UITableViewCell {

    @IBOutlet weak var infoLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func bind(transaction: TransactionRecord, index: Int, lastBlockHeight: Int?) {
        let fromAddress = transaction.from.address
        let toAddress = transaction.to.address

        var confirmations = "n/a"

        if let lastBlockHeight = lastBlockHeight, let blockHeight = transaction.blockHeight {
            confirmations = "\(lastBlockHeight - blockHeight + 1)"
        }

        infoLabel?.text =
                "# \(index)\n" +
                "Amount: \(transaction.amount)\n" +
                "Date: \(transaction.timestamp)\n" +
                "Tx Hash: \(transaction.transactionHash.prefix(10))...\n" +
                "From: \(fromAddress)\n" +
                "To: \(toAddress)\n" +
                "Confirmations: \(confirmations)"
    }

}

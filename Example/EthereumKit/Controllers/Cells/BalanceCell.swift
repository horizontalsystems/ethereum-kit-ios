import UIKit

class BalanceCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?
    @IBOutlet weak var errorLabel: UILabel?

    func bind(adapter: IAdapter) {
        let syncStateString: String
        let txSyncStateString: String

        var errorTexts = [String]()

        switch adapter.syncState {
        case .synced:
            syncStateString = "Synced!"
        case .syncing(let progress):
            if let progress = progress {
                syncStateString = "Syncing \(Int(progress * 100)) %"
            } else {
                syncStateString = "Syncing"
            }
        case .notSynced(let error):
            syncStateString = "Not Synced"
            errorTexts.append("Sync Error: \(error)")
        }

        switch adapter.transactionsSyncState {
        case .synced:
            txSyncStateString = "Synced!"
        case .syncing(let progress):
            if let progress = progress {
                txSyncStateString = "Syncing \(Int(progress * 100)) %"
            } else {
                txSyncStateString = "Syncing"
            }
        case .notSynced(let error):
            txSyncStateString = "Not Synced"
            errorTexts.append("Tx Sync Error: \(error)")
        }

        nameLabel?.text = adapter.name
        errorLabel?.text = errorTexts.joined(separator: "\n")

        set(string: """
                    Sync state:
                    Tx Sync state:
                    Last block height:
                    Balance:
                    """, alignment: .left, label: titleLabel)

        set(string: """
                    \(syncStateString)
                    \(txSyncStateString)
                    \(adapter.lastBlockHeight.map { "# \($0)" } ?? "n/a")
                    \(adapter.balance) \(adapter.coin)
                    """, alignment: .right, label: valueLabel)
    }

    private func set(string: String, alignment: NSTextAlignment, label: UILabel?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = alignment

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        label?.attributedText = attributedString
    }

}

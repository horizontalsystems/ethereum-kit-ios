import UIKit
import SnapKit
import NftKit

class NftCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(12)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .gray

        contentView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview().inset(12)
        }

        valueLabel.numberOfLines = 0
        valueLabel.font = .systemFont(ofSize: 12)
        valueLabel.textColor = .black
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func shortened(value: String) -> String {
        guard value.count > 20 else {
            return value
        }

        return String(value.prefix(8)) + "..." + String(value.suffix(8))
    }

    func bind(nftBalance: NftBalance) {
        set(string: """
                    Name:
                    Type:
                    Contract:
                    ID:
                    Balance:
                    """, alignment: .left, label: titleLabel)

        set(string: """
                    \(nftBalance.nft.tokenName)
                    \(nftBalance.nft.type)
                    \(shortened(value: nftBalance.nft.contractAddress.hex))
                    \(shortened(value: nftBalance.nft.tokenId.description))
                    \(nftBalance.balance)
                    """, alignment: .right, label: valueLabel)
    }

    private func set(string: String, alignment: NSTextAlignment, label: UILabel) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = alignment

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        label.attributedText = attributedString
    }

}

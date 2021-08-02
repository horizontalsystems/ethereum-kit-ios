import Foundation
import UIKit
import EthereumKit
import BigInt
import Erc20Kit
import UniswapKit
import OneInchKit

class TransactionCell: UITableViewCell {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, HH:mm:ss")
        return formatter
    }()

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?

    func bind(transaction: TransactionRecord, coin: String, lastBlockHeight: Int?) {
        var confirmations = "n/a"

        if let lastBlockHeight = lastBlockHeight, let blockHeight = transaction.blockHeight {
            confirmations = "\(lastBlockHeight - blockHeight + 1)"
        }

        set(string: """
                    Tx Hash:
                    Tx Index:
                    Inter Tx Index:
                    Date:
                    Value:
                    \(transaction.from.mine ? "To" : "From")
                    Block:
                    Confirmations:
                    Failed:
                    Decoration:
                    Events:
                    """, alignment: .left, label: titleLabel)

        let fromAddress = transaction.from.address.map { format(hash: $0.eip55) } ?? "n/a"
        let toAddress = transaction.to.address.map { format(hash: $0.eip55) } ?? "n/a"

        set(string: """
                    \(format(hash: transaction.transactionHash))
                    \(transaction.transactionIndex)
                    \(transaction.interTransactionIndex)
                    \(TransactionCell.dateFormatter.string(from: Date(timeIntervalSince1970: Double(transaction.timestamp))))
                    \(transaction.amount) ETH
                    \(transaction.from.mine ? toAddress : fromAddress)
                    \(transaction.blockHeight.map { "# \($0)" } ?? "n/a")
                    \(confirmations)
                    \(transaction.isError)
                    \(transaction.mainDecoration.flatMap { stringify(decoration: $0, transaction: transaction) } ?? "n/a")
                    \(stringify(events: transaction.eventsDecorations, transaction: transaction))
                    """, alignment: .right, label: valueLabel)
    }

    private func stringify(events: [ContractEventDecoration], transaction: TransactionRecord) -> String {
        events
                .map { event -> String in
                    switch event {
                    case let transfer as TransferEventDecoration:
                        let coin = Manager.shared.erc20Tokens[transfer.contractAddress.eip55] ?? "n/a"
                        let fromAddress = transfer.from.eip55.prefix(6)
                        let toAddress = transfer.to.eip55.prefix(6)
                        return "\(bigUIntToString(amount: transfer.value)) \(coin) (\(fromAddress) -> \(toAddress))"

                    case let approve as ApproveEventDecoration:
                        let coin = Manager.shared.erc20Tokens[approve.contractAddress.eip55] ?? "n/a"
                        let owner = approve.owner.eip55.prefix(6)
                        let spender = approve.spender.eip55.prefix(6)
                        return "\(bigUIntToString(amount: approve.value)) \(coin) (\(owner) -approved-> \(spender))"

                    default: return "unknown event"
                    }
                }
                .joined(separator: "\n")
    }

    private func stringify(decoration: TransactionDecoration, transaction: TransactionRecord) -> String {
        let coinName = Manager.shared.erc20Tokens[transaction.to.address!.eip55] ?? "n/a"
        let fromAddress = transaction.from.address!.eip55.prefix(6)

        switch decoration {
        case let swap as OneInchUnoswapMethodDecoration:
            return "\(bigUIntToString(amount: swap.amountIn)) \(stringify(token: swap.tokenIn)) <-> \(bigUIntToString(amount: swap.amountOut ?? swap.amountOutMin)) \(stringify(token: swap.tokenOut))"

        case let swap as OneInchSwapMethodDecoration:
            return "\(bigUIntToString(amount: swap.amountIn)) \(stringify(token: swap.tokenIn)) <-> \(bigUIntToString(amount: swap.amountOut ?? swap.amountOutMin)) \(stringify(token: swap.tokenOut))"

        case let swap as SwapMethodDecoration:
            return "\(amountIn(trade: swap.trade)) \(stringify(token: swap.tokenIn)) <-> \(amountOut(trade: swap.trade)) \(stringify(token: swap.tokenOut))"

        case let transfer as TransferMethodDecoration:
            return "\(bigUIntToString(amount: transfer.value)) \(coinName) (\(fromAddress) -> \(transfer.to.eip55.prefix(6)))"

        case let approve as ApproveMethodDecoration:
            return "\(bigUIntToString(amount: approve.value)) \(coinName) approved"

        case let recognized as RecognizedMethodDecoration:
            return "\(recognized.method)(\(recognized.arguments.count) arguments)"

        default: return "contract call"
        }
    }

    private func stringify(token: SwapMethodDecoration.Token) -> String {
        switch token {
        case .evmCoin: return "ETH"
        case .eip20Coin(let address): return Manager.shared.erc20Tokens[address.eip55] ?? "n/a"
        }
    }

    private func stringify(token: OneInchMethodDecoration.Token?) -> String {
        guard let token = token else {
            return ""
        }
        switch token {
        case .evmCoin: return "ETH"
        case .eip20Coin(let address): return Manager.shared.erc20Tokens[address.eip55] ?? "n/a"
        }
    }

    private func amountIn(trade: SwapMethodDecoration.Trade) -> String {
        let amount: BigUInt
        switch trade {
        case .exactIn(let amountIn, _, _): amount = amountIn
        case .exactOut(_, let amountInMax, let amountIn): amount = amountIn ?? amountInMax
        }

        return bigUIntToString(amount: amount)
    }

    private func amountOut(trade: SwapMethodDecoration.Trade) -> String {
        let amount: BigUInt
        switch trade {
        case .exactIn(_, let amountOutMin, let amountOut): amount = amountOut ?? amountOutMin
        case .exactOut(let amountOut, _, _): amount = amountOut
        }

        return bigUIntToString(amount: amount)
    }

    private func bigUIntToString(amount: BigUInt) -> String {
        Decimal(string: amount.description).flatMap {
            let decimalAmount = Decimal(sign: .plus, exponent: -18, significand: $0)
            return decimalAmount.description
        } ?? ""
    }

    private func set(string: String, alignment: NSTextAlignment, label: UILabel?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = alignment

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        label?.attributedText = attributedString
    }

    private func format(hash: String) -> String {
        guard hash.count > 22 else {
            return hash
        }

        return "\(hash[..<hash.index(hash.startIndex, offsetBy: 10)])...\(hash[hash.index(hash.endIndex, offsetBy: -10)...])"
    }

}

import Foundation
import EthereumKit
import RxSwift
import BigInt

class EthereumAdapter: EthereumBaseAdapter {
    let evmSignerKit: SignerKit
    private let decimal = 18

    init(ethereumSignerKit: SignerKit, ethereumKit: Kit) {
        evmSignerKit = ethereumSignerKit

        super.init(ethereumKit: ethereumKit)
    }

    override func sendSingle(to: Address, amount: Decimal, gasLimit: Int) -> Single<Void> {
        let amount = BigUInt(amount.roundedString(decimal: decimal))!
        let transactionData = evmKit.transferTransactionData(to: to, value: amount)

        return evmSignerKit.sendSingle(transactionData: transactionData, gasPrice: 50_000_000_000, gasLimit: gasLimit).map { _ in ()}
    }

}

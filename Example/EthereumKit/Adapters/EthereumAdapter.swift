import Foundation
import EthereumKit
import RxSwift
import BigInt

class EthereumAdapter: EthereumBaseAdapter {
    let signer: Signer
    private let decimal = 18

    init(signer: Signer, ethereumKit: Kit) {
        self.signer = signer

        super.init(ethereumKit: ethereumKit)
    }

    override func sendSingle(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void> {
        let amount = BigUInt(amount.roundedString(decimal: decimal))!
        let transactionData = evmKit.transferTransactionData(to: to, value: amount)

        return evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw EthereumKit.Kit.KitError.weakReference
                    }

                    let signature = try strongSelf.signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .map { (tx: FullTransaction) in () }
    }

}

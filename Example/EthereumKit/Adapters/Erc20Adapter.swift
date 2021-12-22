import EthereumKit
import Erc20Kit
import RxSwift
import BigInt

class Erc20Adapter: Erc20BaseAdapter {
    private let signer: EthereumKit.Signer

    init(signer: EthereumKit.Signer, ethereumKit: EthereumKit.Kit, token: Erc20Token) {
        self.signer = signer
        super.init(ethereumKit: ethereumKit, token: token)
    }

    func allowanceSingle(spenderAddress: Address) -> Single<Decimal> {
        erc20Kit.allowanceSingle(spenderAddress: spenderAddress)
                .map { [unowned self] allowanceString in
                    if let significand = Decimal(string: allowanceString) {
                        return Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
                    }

                    return 0
                }
    }

    override func sendSingle(to: Address, amount: Decimal, gasLimit: Int) -> Single<Void> {
        let value = BigUInt(amount.roundedString(decimal: token.decimal))!
        let transactionData = erc20Kit.transferTransactionData(to: to, value: value)

        return ethereumKit
                .rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw Signer.SendError.weakReferenceError
                    }

                    let signature = try strongSelf.signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.ethereumKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .map { (tx: FullTransaction) in () }
    }

}

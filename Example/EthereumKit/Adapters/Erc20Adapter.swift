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
                .flatMap { [weak self] allowanceString in
                    guard let strongSelf = self else {
                        throw Kit.KitError.weakReference
                    }

                    if let significand = Decimal(string: allowanceString) {
                        return Single.just(Decimal(sign: .plus, exponent: -strongSelf.token.decimal, significand: significand))
                    }

                    return Single.just(0)
                }
    }

    override func sendSingle(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void> {
        let value = BigUInt(amount.roundedString(decimal: token.decimal))!
        let transactionData = erc20Kit.transferTransactionData(to: to, value: value)

        return ethereumKit
                .rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw EthereumKit.Kit.KitError.weakReference
                    }

                    let signature = try strongSelf.signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.ethereumKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .map { (tx: FullTransaction) in () }
    }

}

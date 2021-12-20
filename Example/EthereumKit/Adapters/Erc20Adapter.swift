import EthereumKit
import Erc20Kit
import RxSwift
import BigInt

class Erc20Adapter: Erc20BaseAdapter {
    private let signerKit: EthereumKit.SignerKit

    init(signerKit: EthereumKit.SignerKit, ethereumKit: EthereumKit.Kit, token: Erc20Token) {
        self.signerKit = signerKit
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

        return signerKit.sendSingle(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit).map { _ in ()}
    }

}

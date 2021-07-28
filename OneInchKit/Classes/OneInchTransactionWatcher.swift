import EthereumKit
import RxSwift
import BigInt

class OneInchTransactionWatcher {
    private let address: Address

    init(address: Address) {
        self.address = address
    }
}

extension OneInchTransactionWatcher: ITransactionWatcher {

    public func needInternalTransactions(fullTransaction: FullTransaction) -> Bool {
        guard fullTransaction.internalTransactions.isEmpty,
              let mainDecoration = fullTransaction.mainDecoration as? OneInchSwapMethodDecoration,
              case .evmCoin = mainDecoration.tokenOut,
              fullTransaction.transaction.from == address && mainDecoration.recipient != address else {
            return false
        }

        return true
    }

}

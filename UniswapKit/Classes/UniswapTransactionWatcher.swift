import EthereumKit
import RxSwift
import BigInt

class UniswapTransactionWatcher {
    private let address: Address

    init(address: Address) {
        self.address = address
    }
}

extension UniswapTransactionWatcher: ITransactionWatcher {

    public func needInternalTransactions(fullTransaction: FullTransaction) -> Bool {
        guard fullTransaction.internalTransactions.isEmpty,
              let mainDecoration = fullTransaction.mainDecoration as? SwapMethodDecoration,
              case .evmCoin = mainDecoration.tokenOut,
              fullTransaction.transaction.from == address && mainDecoration.to != address else {
            return false
        }

        return true
    }

}

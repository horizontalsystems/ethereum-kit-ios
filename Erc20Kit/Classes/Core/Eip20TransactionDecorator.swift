import EthereumKit
import BigInt

class Eip20TransactionDecorator {
    private let userAddress: Address

    init(userAddress: Address) {
        self.userAddress = userAddress
    }

}

extension Eip20TransactionDecorator: ITransactionDecorator {

    public func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration? {
        guard let from = from, let to = to, let value = value, let contractMethod = contractMethod else {
            return nil
        }

        if let transferMethod = contractMethod as? TransferMethod {
            if from == userAddress {
                return OutgoingEip20Decoration(
                        contractAddress: to,
                        to: transferMethod.to,
                        value: transferMethod.value,
                        sentToSelf: transferMethod.to == userAddress,
                        tokenInfo: eventInstances.compactMap { $0 as? TransferEventInstance }.first { $0.contractAddress == to }?.tokenInfo
                )
            }
        }

        if let approveMethod = contractMethod as? ApproveMethod {
            return ApproveEip20Decoration(
                    contractAddress: to,
                    spender: approveMethod.spender,
                    value: approveMethod.value
            )
        }

        return nil
    }

}

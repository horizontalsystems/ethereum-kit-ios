import EthereumKit
import BigInt

class Eip1155TransactionDecorator {
    private let userAddress: Address

    init(userAddress: Address) {
        self.userAddress = userAddress
    }

}

extension Eip1155TransactionDecorator: ITransactionDecorator {

    public func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration? {
        guard let from = from, let to = to, let value = value, let contractMethod = contractMethod else {
            return nil
        }

        if let transferMethod = contractMethod as? Eip1155SafeTransferFromMethod {
            if from == userAddress {
                return OutgoingEip1155Decoration(
                        contractAddress: to,
                        to: transferMethod.to,
                        tokenId: transferMethod.tokenId,
                        value: transferMethod.value,
                        sentToSelf: transferMethod.to == userAddress,
                        tokenInfo: eventInstances.compactMap { $0 as? Eip1155TransferEventInstance }.first { $0.contractAddress == to }?.tokenInfo
                )
            }
        }

        return nil
    }

}

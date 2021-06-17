import EthereumKit
import BigInt

extension Array {

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

}

extension TransactionLog {

    public func erc20Event() -> ContractEventDecoration? {
        guard topics.count == 3 else {
            return nil
        }

        let signature = topics[0]
        let firstParam = Address(raw: topics[1])
        let secondParam = Address(raw: topics[2])

        if signature == TransferEventDecoration.signature {
            return TransferEventDecoration(contractAddress: address, from: firstParam, to: secondParam, value: BigUInt(data))
        }

        if signature == ApproveEventDecoration.signature {
            return ApproveEventDecoration(contractAddress: address, owner: firstParam, spender: secondParam, value: BigUInt(data))
        }

        return nil
    }

}

import EthereumKit
import BigInt

extension Array {

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

}

extension TransactionLog {

    public func erc20Event() -> Erc20LogEvent? {
        guard topics.count == 3 else {
            return nil
        }

        let signature = topics[0]
        let firstParam = Address(raw: topics[1])
        let secondParam = Address(raw: topics[2])

        if signature == Erc20LogEvent.transferSignature {
            return .transfer(from: firstParam, to: secondParam, value: BigUInt(data))
        }

        if signature == Erc20LogEvent.approvalSignature {
            return .approve(owner: firstParam, spender: secondParam, value: BigUInt(data))
        }

        return nil
    }

}

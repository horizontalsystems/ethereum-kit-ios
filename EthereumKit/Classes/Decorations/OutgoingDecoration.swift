import BigInt

public class OutgoingDecoration: TransactionDecoration {
    public let to: Address
    public let value: BigUInt
    public let sentToSelf: Bool

    init(to: Address, value: BigUInt, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf
    }

    public override func tags() -> [String] {
        var tags = [TransactionTag.evmCoin, "\(TransactionTag.evmCoin)_outgoing", "outgoing"]

        if sentToSelf {
            tags += ["\(TransactionTag.evmCoin)_incoming", "incoming"]
        }

        return tags
    }

}

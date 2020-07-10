public struct TradeOptions {
    public let allowedSlippage: Double
    public let ttl: TimeInterval
    public let recipient: String
    public let feeOnTransfer: Bool

    public init(allowedSlippage: Double = 0.5, ttl: TimeInterval = 20 * 60, recipient: String, feeOnTransfer: Bool = false) {
        self.allowedSlippage = allowedSlippage
        self.ttl = ttl
        self.recipient = recipient
        self.feeOnTransfer = feeOnTransfer
    }

}

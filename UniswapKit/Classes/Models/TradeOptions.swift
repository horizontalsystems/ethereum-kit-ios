public struct TradeOptions {
    public var allowedSlippage: Double
    public var ttl: TimeInterval
    public var recipient: Data?
    public var feeOnTransfer: Bool

    public init(allowedSlippage: Double = 0.5, ttl: TimeInterval = 20 * 60, recipient: Data? = nil, feeOnTransfer: Bool = false) {
        self.allowedSlippage = allowedSlippage
        self.ttl = ttl
        self.recipient = recipient
        self.feeOnTransfer = feeOnTransfer
    }

}

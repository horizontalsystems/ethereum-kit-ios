public struct TradeOptions {
    public var allowedSlippage: Decimal
    public var ttl: TimeInterval
    public var recipient: Data?
    public var feeOnTransfer: Bool

    public init(allowedSlippage: Decimal = 0.5, ttl: TimeInterval = 20 * 60, recipient: Data? = nil, feeOnTransfer: Bool = false) {
        self.allowedSlippage = allowedSlippage
        self.ttl = ttl
        self.recipient = recipient
        self.feeOnTransfer = feeOnTransfer
    }

    var slippageFraction: Fraction {
        Fraction(decimal: allowedSlippage / 100) ?? Fraction(numerator: 5, denominator: 1000)
    }

}

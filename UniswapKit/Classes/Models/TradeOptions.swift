import EthereumKit

public struct TradeOptions {
    public var allowedSlippage: Decimal
    public var ttl: TimeInterval
    public var recipient: Address?
    public var feeOnTransfer: Bool

    public init(allowedSlippage: Decimal = 0.5, ttl: TimeInterval = 20 * 60, recipient: Address? = nil, feeOnTransfer: Bool = false) {
        self.allowedSlippage = allowedSlippage
        self.ttl = ttl
        self.recipient = recipient
        self.feeOnTransfer = feeOnTransfer
    }

    var slippageFraction: Fraction {
        do {
            return try Fraction(decimal: allowedSlippage / 100)
        } catch {
            return Fraction(numerator: 5, denominator: 1000)
        }
    }

}

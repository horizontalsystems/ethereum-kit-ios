import EthereumKit

public struct TradeOptions {
    public static let defaultSlippage: Decimal = 0.5
    public static let defaultTtl: TimeInterval = 20 * 60

    public var allowedSlippage: Decimal
    public var ttl: TimeInterval
    public var recipient: Address?
    public var feeOnTransfer: Bool

    public init(allowedSlippage: Decimal = TradeOptions.defaultSlippage, ttl: TimeInterval = TradeOptions.defaultTtl, recipient: Address? = nil, feeOnTransfer: Bool = false) {
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

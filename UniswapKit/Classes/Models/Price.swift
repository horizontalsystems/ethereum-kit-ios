import BigInt

struct Price {
    private let baseToken: Token
    private let quoteToken: Token
    let fraction: Fraction
    private let scalar: Fraction

    init(baseToken: Token, quoteToken: Token, fraction: Fraction) {
        self.baseToken = baseToken
        self.quoteToken = quoteToken
        self.fraction = fraction

        scalar = Fraction(
                numerator: BigUInt(10).power(baseToken.decimals),
                denominator: BigUInt(10).power(quoteToken.decimals)
        )
    }

    init(baseTokenAmount: TokenAmount, quoteTokenAmount: TokenAmount) {
        self.init(
                baseToken: baseTokenAmount.token,
                quoteToken: quoteTokenAmount.token,
                fraction: Fraction(numerator: quoteTokenAmount.rawAmount, denominator: baseTokenAmount.rawAmount)
        )
    }

    var adjusted: Fraction {
        fraction * scalar
    }

    var decimalValue: Decimal? {
        adjusted.toDecimal(decimals: quoteToken.decimals)
    }

}

extension Price {

    public static func *(lhs: Price, rhs: Price) -> Price {
        let fraction = lhs.fraction * rhs.fraction
        return Price(baseToken: lhs.baseToken, quoteToken: rhs.quoteToken, fraction: fraction)
    }

}

extension Price: CustomStringConvertible {

    public var description: String {
        "[baseToken: \(baseToken); quoteToken: \(quoteToken); value: \(decimalValue?.description ?? "nil")]"
    }

}

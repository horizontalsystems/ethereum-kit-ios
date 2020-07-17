import BigInt

struct TokenAmount {
    let token: Token
    let fraction: Fraction

    init(token: Token, rawAmount: BigUInt) {
        self.token = token
        self.fraction = Fraction(numerator: rawAmount, denominator: BigUInt(10).power(token.decimals))
    }

    init(token: Token, decimal: Decimal) throws {
        guard decimal.sign == .plus else {
            throw Kit.FractionError.negativeDecimal
        }

        guard let significand = BigUInt(decimal.significand.description) else {
            throw Kit.FractionError.invalidSignificand(value: decimal.significand.description)
        }

        let rawAmount: BigUInt

        if decimal.exponent < -token.decimals {
            rawAmount = significand / BigUInt(10).power(-decimal.exponent - token.decimals)
        } else {
            rawAmount = significand * BigUInt(10).power(token.decimals + decimal.exponent)
        }

        self.init(token: token, rawAmount: rawAmount)
    }

    var rawAmount: BigUInt {
        fraction.numerator
    }

    var decimalAmount: Decimal? {
        fraction.toDecimal(decimals: token.decimals)
    }

}

extension TokenAmount: Comparable {

    public static func <(lhs: TokenAmount, rhs: TokenAmount) -> Bool {
        lhs.fraction < rhs.fraction
    }

    public static func ==(lhs: TokenAmount, rhs: TokenAmount) -> Bool {
        lhs.fraction == rhs.fraction
    }

}

extension TokenAmount: CustomStringConvertible {

    public var description: String {
        let amountString = decimalAmount?.description ?? "nil"
        return "[token: \(token); amount: \(amountString)]"
    }

}

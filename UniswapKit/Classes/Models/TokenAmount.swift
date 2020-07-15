import BigInt

struct TokenAmount {
    let token: Token
    private let fraction: Fraction

    init(token: Token, rawAmount: BigUInt) {
        self.token = token
        self.fraction = Fraction(numerator: rawAmount, denominator: BigUInt(10).power(token.decimals))
    }

    init?(token: Token, decimal: Decimal) {
        guard decimal.sign == .plus else {
            return nil
        }

        guard let significand = BigUInt(decimal.significand.description) else {
            return nil
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

extension TokenAmount: CustomStringConvertible {

    public var description: String {
        let amountString = decimalAmount?.description ?? "nil"
        return "[token: \(token); amount: \(amountString)]"
    }

}

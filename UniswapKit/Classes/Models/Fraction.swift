import BigInt

struct Fraction {
    let numerator: BigUInt
    let denominator: BigUInt

    init(numerator: BigUInt, denominator: BigUInt = 1) {
        self.numerator = numerator
        self.denominator = numerator == 0 ? 1 : denominator
    }

    init(decimal: Decimal) throws {
        guard decimal.sign == .plus else {
            throw Kit.FractionError.negativeDecimal
        }

        guard let numerator = BigUInt(decimal.significand.description) else {
            throw Kit.FractionError.invalidSignificand(value: decimal.significand.description)
        }

        if decimal.exponent > 0 {
            self.numerator = numerator * BigUInt(10).power(decimal.exponent)
            self.denominator = 1
        } else {
            self.numerator = numerator
            self.denominator = BigUInt(10).power(-decimal.exponent)
        }
    }

    var quotient: BigUInt {
        numerator / denominator
    }

    var inverted: Fraction {
        Fraction(numerator: denominator, denominator: numerator)
    }

    func toDecimal(decimals: Int) -> Decimal? {
        let adjustedNumerator = numerator * BigUInt(10).power(decimals)
        let value = adjustedNumerator / denominator

        guard let significand = Decimal(string: value.description) else {
            return nil
        }

        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }

}

extension Fraction {

    public static func +(lhs: Fraction, rhs: Fraction) -> Fraction {
        if lhs.denominator == rhs.denominator {
            return Fraction(numerator: lhs.numerator + rhs.numerator, denominator: lhs.denominator)
        }

        return Fraction(
                numerator: lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator,
                denominator: lhs.denominator * rhs.denominator
        )
    }

    public static func -(lhs: Fraction, rhs: Fraction) -> Fraction {
        if lhs.denominator == rhs.denominator {
            return Fraction(numerator: lhs.numerator - rhs.numerator, denominator: lhs.denominator)
        }

        return Fraction(
                numerator: lhs.numerator * rhs.denominator - rhs.numerator * lhs.denominator,
                denominator: lhs.denominator * rhs.denominator
        )
    }

    public static func *(lhs: Fraction, rhs: Fraction) -> Fraction {
        Fraction(
                numerator: lhs.numerator * rhs.numerator,
                denominator: lhs.denominator * rhs.denominator
        )
    }

    public static func /(lhs: Fraction, rhs: Fraction) -> Fraction {
        Fraction(
                numerator: lhs.numerator * rhs.denominator,
                denominator: lhs.denominator * rhs.numerator
        )
    }

}

extension Fraction: Comparable {

    public static func <(lhs: Fraction, rhs: Fraction) -> Bool {
        lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }

    public static func ==(lhs: Fraction, rhs: Fraction) -> Bool {
        lhs.numerator * rhs.denominator == rhs.numerator * lhs.denominator
    }

}

extension Fraction: CustomStringConvertible {

    public var description: String {
        "\(numerator) / \(denominator)"
    }

}

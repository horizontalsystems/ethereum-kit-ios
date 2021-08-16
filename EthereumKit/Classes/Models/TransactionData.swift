import BigInt

public struct TransactionData {
    public var to: Address
    public var value: BigUInt
    public var input: Data
    public var nonce: Int?
    
    public init(to: Address, value: BigUInt, input: Data, nonce: Int? = nil) {
        self.to = to
        self.value = value
        self.input = input
        self.nonce = nonce
    }
}

extension TransactionData: Equatable {

    public static func ==(lhs: TransactionData, rhs: TransactionData) -> Bool {
        lhs.to == rhs.to && lhs.value == rhs.value && lhs.input == rhs.input && lhs.nonce == rhs.nonce
    }

}

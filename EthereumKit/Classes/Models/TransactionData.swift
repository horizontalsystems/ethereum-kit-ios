import BigInt

public struct TransactionData {
    public var to: Address
    public var value: BigUInt
    public var input: Data
    
    public init(to: Address, value: BigUInt, input: Data) {
        self.to = to
        self.value = value
        self.input = input
    }
}

class RawTransaction {
    let gasPrice: Int
    let gasLimit: Int
    let to: Address
    let value: BInt
    let data: Data

    init(gasPrice: Int, gasLimit: Int, to: Address, value: BInt, data: Data = Data()) {
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
    }

}

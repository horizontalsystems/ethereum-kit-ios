class RawTransaction {
    let gasPrice: Int
    let gasLimit: Int
    let to: Data
    let value: BInt
    let data: Data

    init(gasPrice: Int, gasLimit: Int, to: Data, value: BInt, data: Data) {
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
    }

}

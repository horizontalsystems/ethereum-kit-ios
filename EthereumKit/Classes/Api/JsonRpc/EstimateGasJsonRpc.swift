import BigInt

class EstimateGasJsonRpc: IntJsonRpc {
    let from: Address
    let to: Address
    var amount: BigUInt?
    var gasLimit: Int?
    var gasPrice: Int?
    var data: Data?

    init(from: Address, to: Address, amount: BigUInt?, gasLimit: Int?, gasPrice: Int?, data: Data?) {
        self.from = from
        self.to = to
        self.amount = amount
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.data = data

        var params: [String: Any] = [
            "from": from.hex,
            "to": to.hex
        ]

        if let amount = amount {
            params["value"] = "0x" + amount.serialize().hex.removeLeadingZeros()
        }
        if let gasLimit = gasLimit {
            params["gas"] = "0x" + String(gasLimit, radix: 16).removeLeadingZeros()
        }
        if let gasPrice = gasPrice {
            params["gasPrice"] = "0x" + String(gasPrice, radix: 16).removeLeadingZeros()
        }
        if let data = data {
            params["data"] = data.toHexString()
        }

        super.init(
                method: "eth_estimateGas",
                params: [params]
        )
    }

}

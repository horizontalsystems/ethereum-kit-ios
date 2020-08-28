import BigInt

class GetBalanceJsonRpc: JsonRpc<BigUInt> {
    let address: Address
    let defaultBlockParameter: DefaultBlockParameter

    init(address: Address, defaultBlockParameter: DefaultBlockParameter) {
        self.address = address
        self.defaultBlockParameter = defaultBlockParameter

        super.init(
                method: "eth_getBalance",
                params: [address.hex, defaultBlockParameter.raw]
        )
    }

    override func parse(result: Any) throws -> BigUInt {
        guard let hexString = result as? String else {
            throw ParseError.invalidResult(value: result)
        }

        guard let value = BigUInt(hexString.stripHexPrefix(), radix: 16) else {
            throw ParseError.invalidHex(value: hexString)
        }

        return value
    }

}

extension GetBalanceJsonRpc {

    enum ParseError: Error {
        case invalidResult(value: Any)
        case invalidHex(value: String)
    }

}

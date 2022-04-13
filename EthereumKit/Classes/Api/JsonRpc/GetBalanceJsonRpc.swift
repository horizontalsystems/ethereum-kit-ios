import BigInt

class GetBalanceJsonRpc: JsonRpc<BigUInt> {

    init(address: Address, defaultBlockParameter: DefaultBlockParameter) {
        super.init(
                method: "eth_getBalance",
                params: [address.hex, defaultBlockParameter.raw]
        )
    }

    override func parse(result: Any) throws -> BigUInt {
        guard let hexString = result as? String, let value = BigUInt(hexString.stripHexPrefix(), radix: 16) else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return value
    }

}

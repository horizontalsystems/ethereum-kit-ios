import Foundation

class GetLogsJsonRpc: JsonRpc<[TransactionLog]> {

    init(address: Address?, fromBlock: DefaultBlockParameter?, toBlock: DefaultBlockParameter?, topics: [Any?]?) {
        var params = [String: Any]()

        if let address = address {
            params["address"] = address.hex
        }

        if let fromBlock = fromBlock {
            params["fromBlock"] = fromBlock.raw
        }

        if let toBlock = toBlock {
            params["toBlock"] = toBlock.raw
        }

        if let topics = topics {
            params["topics"] = topics.map { topic -> Any? in
                if let array = topic as? [Data?] {
                    return array.map { topic -> String? in
                        topic?.toHexString()
                    }
                } else if let data = topic as? Data {
                    return data.toHexString()
                } else {
                    return nil
                }
            }
        }

        super.init(
                method: "eth_getLogs",
                params: [params]
        )
    }

    override func parse(result: Any) throws -> [TransactionLog] {
        guard let array = result as? [Any] else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return try array.map { jsonObject in
            try TransactionLog(JSONObject: jsonObject)
        }
    }

}

import Foundation

class GetLogsJsonRpc: JsonRpc<[EthereumLog]> {

    init(address: Address?, fromBlock: Int, toBlock: Int, topics: [Any?]) {
        let toBlockStr = "0x" + String(toBlock, radix: 16)
        let fromBlockStr = "0x" + String(fromBlock, radix: 16)

        let jsonTopics: [Any?] = topics.map {
            if let array = $0 as? [Data?] {
                return array.map { topic -> String? in
                    topic?.toHexString()
                }
            } else if let data = $0 as? Data {
                return data.toHexString()
            } else {
                return nil
            }
        }

        let params: [String: Any] = [
            "fromBlock": fromBlockStr,
            "toBlock": toBlockStr,
            "address": address?.hex as Any,
            "topics": jsonTopics
        ]

        super.init(
                method: "eth_getLogs",
                params: [params]
        )
    }

    override func parse(result: Any) throws -> [EthereumLog] {
        guard let resultArray = result as? [Any] else {
            throw ResponseError.invalidResult(value: result)
        }

        return try resultArray.map { logJson in
            guard let log = EthereumLog(json: logJson) else {
                throw ResponseError.invalidResult(value: result)
            }

            return log
        }
    }

}

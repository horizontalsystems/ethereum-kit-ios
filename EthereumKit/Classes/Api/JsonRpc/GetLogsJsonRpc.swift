import Foundation

class GetLogsJsonRpc: JsonRpc<[EthereumLog]> {
    let address: Address?
    let fromBlock: Int
    let toBlock: Int
    let topics: [Any?]

    init(address: Address?, fromBlock: Int, toBlock: Int, topics: [Any?]) {
        self.address = address
        self.fromBlock = fromBlock
        self.toBlock = toBlock
        self.topics = topics

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
            throw ParseError.invalidResult(value: result)
        }

        return try resultArray.map { logJson in
            guard let log = EthereumLog(json: logJson) else {
                throw ParseError.invalidLog(value: logJson)
            }

            return log
        }
    }

}

extension GetLogsJsonRpc {

    enum ParseError: Error {
        case invalidResult(value: Any)
        case invalidLog(value: Any)
    }

}

class NewHeadsRpcSubscription: RpcSubscription<RpcBlockHeader> {

    init() {
        super.init(params: ["newHeads"])
    }

    override func parse(result: Any) throws -> RpcBlockHeader {
        guard let resultMap = result as? [String: Any] else {
            throw ParseError.invalidResult(result: result)
        }

        guard let numberHex = resultMap["number"] as? String, let number = Int(numberHex.stripHexPrefix(), radix: 16) else {
            throw ParseError.noBlockNumber(resultMap: resultMap)
        }

        return RpcBlockHeader(number: number)
    }

}

extension NewHeadsRpcSubscription {

    enum ParseError: Error {
        case invalidResult(result: Any)
        case noBlockNumber(resultMap: [String: Any])
    }

}

struct RpcBlockHeader {
    let number: Int
}

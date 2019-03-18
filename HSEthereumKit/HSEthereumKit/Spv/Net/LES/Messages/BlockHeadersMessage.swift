class BlockHeadersMessage: IInMessage {
    let requestId: Int
    let bv: Int
    let headers: [BlockHeader]

    init(requestId: Int, bv: Int, headers: [BlockHeader]) {
        self.requestId = requestId
        self.bv = bv
        self.headers = headers
    }

    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count > 2 else {
            throw MessageDecodeError.notEnoughFields
        }

        self.requestId = try rlpList[0].intValue()
        self.bv = try rlpList[1].intValue()

        var headers = [BlockHeader]()
        for rlpHeader in try rlpList[2].listValue() {
            headers.append(try BlockHeader(rlp: rlpHeader))
        }

        self.headers = headers
    }

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
//        return "HEADERS [requestId: \(requestId); bv: \(bv); headers: [\(headers.map{ $0.toString() }.joined(separator: ","))]]"
        return "HEADERS [requestId: \(requestId); bv: \(bv.flowControlLog); headersCount: \(headers.count); first: \(headers.first?.toString() ?? "none"); last: \(headers.last?.toString() ?? "none")]"
    }

}

class GetBlockHeadersMessage: IMessage {
    static let maxHeaders = 50

    var requestId: Int
    var blockHash: Data
    var skip: Int
    var reverse: Int  // 0 or 1

    init(requestId: Int, blockHash: Data, skip: Int = 0, reverse: Int = 0) {
        self.requestId = requestId
        self.blockHash = blockHash
        self.skip = skip
        self.reverse = reverse
    }

    required init(data: Data) throws {
        self.requestId = 0
        self.blockHash = Data()
        self.skip = 0
        self.reverse = 0
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            requestId,
            [
                blockHash,
                GetBlockHeadersMessage.maxHeaders,
                skip,
                reverse
            ]
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "GET_HEADERS [requestId: \(requestId); blockHash: \(blockHash.toHexString()); maxHeaders: \(GetBlockHeadersMessage.maxHeaders); skip: \(skip); reverse: \(reverse)]"
    }

}

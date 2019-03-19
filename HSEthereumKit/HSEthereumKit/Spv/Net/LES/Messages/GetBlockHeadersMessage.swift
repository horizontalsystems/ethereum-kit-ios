class GetBlockHeadersMessage: IOutMessage {
    var requestId: Int
    var blockHash: Data
    var maxHeaders: Int
    var skip: Int
    var reverse: Int  // 0 or 1

    init(requestId: Int, blockHash: Data, maxHeaders: Int, skip: Int = 0, reverse: Int = 0) {
        self.requestId = requestId
        self.blockHash = blockHash
        self.maxHeaders = maxHeaders
        self.skip = skip
        self.reverse = reverse
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            requestId,
            [
                blockHash,
                maxHeaders,
                skip,
                reverse
            ]
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "GET_HEADERS [requestId: \(requestId); blockHash: \(blockHash.toHexString()); maxHeaders: \(maxHeaders); skip: \(skip); reverse: \(reverse)]"
    }

}

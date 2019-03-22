class GetBlockHeadersMessage: IOutMessage {
    var requestId: Int
    var blockHeight: Int
    var maxHeaders: Int
    var skip: Int
    var reverse: Int  // 0 or 1

    init(requestId: Int, blockHeight: Int, maxHeaders: Int, skip: Int = 0, reverse: Int = 0) {
        self.requestId = requestId
        self.blockHeight = blockHeight
        self.maxHeaders = maxHeaders
        self.skip = skip
        self.reverse = reverse
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            requestId,
            [
                blockHeight,
                maxHeaders,
                skip,
                reverse
            ]
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "GET_HEADERS [requestId: \(requestId); blockHeight: \(blockHeight); maxHeaders: \(maxHeaders); skip: \(skip); reverse: \(reverse)]"
    }

}

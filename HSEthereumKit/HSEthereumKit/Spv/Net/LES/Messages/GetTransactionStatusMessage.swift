class GetTransactionStatusMessage: IOutMessage {
    let requestId: Int
    let hashes: [Data]

    init(requestId: Int, hashes: [Data]) {
        self.requestId = requestId
        self.hashes = hashes
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            requestId,
            hashes
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "GET_TX_STATUS [requestId: \(requestId), hashes: \(hashes.map { $0.toHexString() }.joined(separator: ", "))]"
    }

}

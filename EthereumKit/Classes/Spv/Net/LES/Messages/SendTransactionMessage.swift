class SendTransactionMessage: IOutMessage {
    let requestId: Int
    let rawTransaction: RawTransaction
    let nonce: Int
    let signature: Signature

    init(requestId: Int, rawTransaction: RawTransaction, nonce: Int, signature: Signature) {
        self.requestId = requestId
        self.rawTransaction = rawTransaction
        self.nonce = nonce
        self.signature = signature
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            requestId,
            [
                [
                    nonce,
                    rawTransaction.gasPrice,
                    rawTransaction.gasLimit,
                    rawTransaction.to.raw,
                    rawTransaction.value,
                    rawTransaction.data,
                    signature.v,
                    signature.r,
                    signature.s
                ]
            ]
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "SEND_TX [requestId: \(requestId), nonce: \(nonce), gasPrice: \(rawTransaction.gasPrice), gasLimit: \(rawTransaction.gasLimit), " +
                "to: \(rawTransaction.to), value: \(rawTransaction.value), data: \(rawTransaction.data.toHexString()), " +
                "v: \(signature.v), r: \(signature.r), s: \(signature.s)]"
    }

}

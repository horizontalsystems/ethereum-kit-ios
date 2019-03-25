class SendTransactionMessage: IOutMessage {
    let requestId: Int
    let rawTransaction: RawTransaction
    let signature: (v: BInt, r: BInt, s: BInt)

    init(requestId: Int, rawTransaction: RawTransaction, signature: (v: BInt, r: BInt, s: BInt)) {
        self.requestId = requestId
        self.rawTransaction = rawTransaction
        self.signature = signature
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            requestId,
            [
                [
                    rawTransaction.nonce,
                    rawTransaction.gasPrice,
                    rawTransaction.gasLimit,
                    rawTransaction.to.data,
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
        return "SEND_TX [requestId: \(requestId), nonce: \(rawTransaction.nonce), gasPrice: \(rawTransaction.gasPrice), gasLimit: \(rawTransaction.gasLimit), " +
                "to: \(rawTransaction.to.string), value: \(rawTransaction.value.asString(withBase: 10)), data: \(rawTransaction.data.toHexString()), " +
                "v: \(signature.v), r: \(signature.r), s: \(signature.s)]"
    }

}

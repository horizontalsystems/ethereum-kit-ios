class GetProofsMessage: IOutMessage {
    let requestId: Int
    var proofRequests: [ProofRequest]

    init(requestId: Int, blockHash: Data, key: Data, key2: Data = Data(), fromLevel: Int = 0) {
        self.requestId = requestId
        self.proofRequests = [ProofRequest(blockHash: blockHash, key: key, key2: key2, fromLevel: fromLevel)]
    }

    func encoded() -> Data {
        let toEncode: [Any] = [
            requestId,
            proofRequests.map{ $0.toArray() }
        ]

        return RLP.encode(toEncode)
    }

    func toString() -> String {
        return "GET_PROOFS [requestId: \(requestId); proofRequests: [\(proofRequests.map{ $0.toString() }.joined(separator: ","))]]"
    }

    class ProofRequest {

        let blockHash: Data
        let key: Data
        let keyHash: Data
        let key2Hash: Data
        let fromLevel: Int

        init(blockHash: Data, key: Data, key2: Data, fromLevel: Int) {
            self.blockHash = blockHash
            self.key = key
            self.keyHash = CryptoUtils.shared.sha3(key)
            if key2.count > 0 {
                self.key2Hash = CryptoUtils.shared.sha3(key2)
            } else {
                self.key2Hash = key2
            }
            self.fromLevel = fromLevel
        }

        func toArray() -> [Any] {
            return [
                blockHash,
                key2Hash,
                keyHash,
                fromLevel
            ]
        }

        func toString() -> String {
            return "(blockHash: \(blockHash.toHexString()); key: \(keyHash.toHexString()); key2: \(key2Hash.toHexString()); fromLevel: \(fromLevel))"
        }

    }

}

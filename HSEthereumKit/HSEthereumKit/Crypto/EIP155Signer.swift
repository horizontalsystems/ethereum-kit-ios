import HSCryptoKit

public struct EIP155Signer {
    
    private let chainID: Int
    
    public init(chainID: Int) {
        self.chainID = chainID
    }
    
    public func sign(_ rawTransaction: RawTransaction, privateKey: Data) throws -> Data {
        let transactionHash = hash(rawTransaction: rawTransaction)
        let signature = try CryptoKit.ellipticSign(transactionHash, privateKey: privateKey)
        
        let (r, s, v) = calculateRSV(signature: signature)
        return RLP.encode([
            rawTransaction.nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.data,
            rawTransaction.value,
            rawTransaction.data,
            v, r, s
        ])
    }
    
    public func hash(rawTransaction: RawTransaction) -> Data {
        return CryptoKit.sha3(encode(rawTransaction: rawTransaction))
    }
    
    public func encode(rawTransaction: RawTransaction) -> Data {
        var toEncode: [Any] = [
            rawTransaction.nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.data,
            rawTransaction.value,
            rawTransaction.data]
        if chainID != 0 {
            toEncode.append(contentsOf: [chainID, 0, 0 ]) // EIP155
        }
        return RLP.encode(toEncode)
    }

    @available(*, deprecated, renamed: "calculateRSV(signature:)")
    public func calculateRSV(signiture: Data) -> (r: BInt, s: BInt, v: BInt) {
        return calculateRSV(signature: signiture)
    }

    public func calculateRSV(signature: Data) -> (r: BInt, s: BInt, v: BInt) {
        return (
            r: BInt(str: signature[..<32].toHexString(), radix: 16)!,
            s: BInt(str: signature[32..<64].toHexString(), radix: 16)!,
            v: BInt(signature[64]) + (chainID == 0 ? 27 : (35 + 2 * chainID))
        )
    }

    public func calculateSignature(r: BInt, s: BInt, v: BInt) -> Data {
        let isOldSignitureScheme = [27, 28].contains(v)
        let suffix = isOldSignitureScheme ? v - 27 : v - 35 - 2 * chainID
        let sigHexStr = hex64Str(r) + hex64Str(s) + suffix.asString(withBase: 16)
        return Data(hex: sigHexStr)
    }

    private func hex64Str(_ i: BInt) -> String {
        let hex = i.asString(withBase: 16)
        return String(repeating: "0", count: 64 - hex.count) + hex
    }
}

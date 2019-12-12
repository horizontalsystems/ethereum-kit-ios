import Foundation
import OpenSslKit

class FrameCodecHelper: IFrameCodecHelper {

    private let crypto: ICryptoUtils

    init(crypto: ICryptoUtils) {
        self.crypto = crypto
    }

    func updateMac(mac: KeccakDigest, macKey: Data, data: Data) -> Data {
        let encryptedMacDigest = crypto.aesEncrypt(mac.digest(), withKey: macKey, keySize: 256)

        mac.update(with: encryptedMacDigest.subdata(in: 0..<16).xor(with: data))
        let checksum = mac.digest().subdata(in: 0..<16)

        return checksum
    }

    func toThreeBytes(int: Int) -> Data {
        var int = int
        var data = Data()

        withUnsafeBytes(of: &int) { ptr in
            let bytes = Array(ptr)
            data += bytes[2]
            data += bytes[1]
            data += bytes[0]
        }

        return data
    }

    func fromThreeBytes(data: Data) -> Int {
        let totalSizeBytes = Data(repeating: 0, count: 1) + data
        let totalSizeBigEndian = totalSizeBytes.to(type: UInt32.self)
        return Int(UInt32(bigEndian: totalSizeBigEndian))
    }
}

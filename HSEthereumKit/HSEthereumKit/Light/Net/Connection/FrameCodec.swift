import Foundation
import HSCryptoKit

class FrameCodec {

    private let secrets: Secrets;
    private let encIV = Data(hex: "00000000000000000000000000000000")
    private let decIV = Data(hex: "00000000000000000000000000000000")
    private var totalBodySize: Int = 0;
    private var contextId: Int = -1;
    private var totalFrameSize: Int = -1;


    init(secrets: Secrets) {
        self.secrets = secrets
    }
    
    func readFrames(from data: Data) -> [Frame] {
        guard data.count >= 64 else {
            return [Frame]()
        }

        let header = data.subdata(in: 0..<16)
        let headerMac = data.subdata(in: 16..<32)
        let updatedMac = updateMac(mac: secrets.ingressMac, macKey: secrets.mac, data: header)

        guard updatedMac == headerMac else {
            print("MAC mismatch!")
            return []
        }

        let decryptedHeader: Data = _AES.encrypt(header, withKey: secrets.aes, keySize: 256, iv: decIV)

        let totalSizeBytes = Data(repeating: 0, count: 1) + decryptedHeader.subdata(in: 0..<3)
        let totalSizeBigEndian = totalSizeBytes.withUnsafeBytes { (ptr: UnsafePointer<UInt32>) -> UInt32 in
            return ptr.pointee
        }
        let frameBodySize = Int(UInt32(bigEndian: totalSizeBigEndian))

        let rlpHeader = try! RLP.decode(input: decryptedHeader.subdata(in: 3..<16))
        var contextId = -1
        if rlpHeader.listValue.count > 1 {
            contextId = rlpHeader.listValue[1].intValue
        }
        var allFramesTotalSize = -1
        if rlpHeader.listValue.count > 2 {
            allFramesTotalSize = rlpHeader.listValue[2].intValue
        }

        let paddingSize = 16 - (frameBodySize % 16)
        let frameSize = 32 + frameBodySize + paddingSize + 16  // header || body || padding || body-mac

        guard data.count >= frameSize else {
            return [Frame]()
        }

        let frameBodyData = data.subdata(in: 32..<(32 + frameBodySize + paddingSize))
        let frameBodyMac = data.subdata(in: (32 + frameBodySize + paddingSize)..<frameSize)

        secrets.ingressMac.update(with: frameBodyData)
        let decryptedFrame: Data = _AES.encrypt(frameBodyData, withKey: secrets.aes, keySize: 256, iv: decIV)

        let rlpPacketType = try! RLP.decode(input: decryptedFrame)
        let packetType = rlpPacketType.intValue
        let packetTypeLength = rlpPacketType.lengthOfLengthBytes + rlpPacketType.length

        let payload = decryptedFrame.subdata(in: packetTypeLength..<frameBodySize)

        let ingressMac = secrets.ingressMac.digest()
        let updatedFrameBodyMac = updateMac(mac: secrets.ingressMac, macKey: secrets.mac, data: ingressMac)

        guard updatedFrameBodyMac == frameBodyMac else {
            print("MAC mismatch!")
            return []
        }

        let frame = Frame(type: packetType, payload: payload, size: frameSize, contextId: contextId, allFramesTotalSize: allFramesTotalSize)

        return [frame]
    }

    func encodeFrame(frame: Frame) -> Data {
        var header = Data()
        let packetType = try! RLP.encode(frame.type)

        var frameSize: Int = frame.payloadSize + packetType.count
        withUnsafeBytes(of: &frameSize) { ptr in
            let bytes = Array(ptr)
            header += bytes[2]
            header += bytes[1]
            header += bytes[0]
        }

        var headerDataElements = [0]
        if contextId > 0 {
            headerDataElements.append(contextId)
        }
        if totalFrameSize > 0 {
            headerDataElements.append(totalFrameSize)
        }

        header += (try! RLP.encode(headerDataElements))
        header += Data(repeating: 0, count: 16 - header.count)

        let encryptedHeader = _AES.encrypt(header, withKey: secrets.aes, keySize: 256, iv: encIV)
        let headerMac = updateMac(mac: secrets.egressMac, macKey: secrets.mac, data: encryptedHeader)

        header = encryptedHeader + headerMac

        let padding = Data(repeating: 0, count: 16 - frameSize % 16)
        var frameData = packetType + frame.payload + padding

        let encryptedFrameData: Data = _AES.encrypt(frameData, withKey: secrets.aes, keySize: 256, iv: encIV)

        secrets.egressMac.update(with: encryptedFrameData)
        let egressMac = secrets.egressMac.digest()

        let frameMac = updateMac(mac: secrets.egressMac, macKey: secrets.mac, data: egressMac)

        frameData = encryptedFrameData + frameMac

        return header + frameData
    }

    private func updateMac(mac: KeccakDigest, macKey: Data, data: Data) -> Data {
        let macDigest = mac.digest()
        let encryptedMacDigest: Data = _AES.encrypt(macDigest, withKey: macKey, keySize: 256)

        mac.update(with: encryptedMacDigest.subdata(in: 0..<16).xor(with: data))
        let checksum = mac.digest().subdata(in: 0..<16)

        return checksum
    }
}


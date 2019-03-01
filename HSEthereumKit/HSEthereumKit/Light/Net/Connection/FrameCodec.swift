import Foundation
import HSCryptoKit

class FrameCodec {

    enum FrameCodecError: Error {
        case macMismatch
    }

    private let secrets: Secrets
    private let helper: IFrameCodecHelper
    private let encryptor: IAESEncryptor
    private let decryptor: IAESEncryptor  // AES in CTR encrypt gives the message back when you encrypt the cipher


    init(secrets: Secrets, helper: IFrameCodecHelper, encryptor: IAESEncryptor, decryptor: IAESEncryptor) {
        self.secrets = secrets
        self.helper = helper
        self.encryptor = encryptor
        self.decryptor = decryptor
    }
    
    func readFrame(from data: Data) throws -> Frame? {
        guard data.count >= 64 else {
            return nil
        }

        let header = data.subdata(in: 0..<16)
        let headerMac = data.subdata(in: 16..<32)
        let updatedMac = helper.updateMac(mac: secrets.ingressMac, macKey: secrets.mac, data: header)

        guard updatedMac == headerMac else {
            throw FrameCodecError.macMismatch
        }

        let decryptedHeader = decryptor.encrypt(header)
        let frameBodySize = helper.fromThreeBytes(data: decryptedHeader.subdata(in: 0..<3))

        let rlpHeader = RLP.decode(input: decryptedHeader.subdata(in: 3..<16))
        var contextId = -1
        if rlpHeader.listValue.count > 1 {
            contextId = rlpHeader.listValue[1].intValue
        }
        var allFramesTotalSize = -1
        if rlpHeader.listValue.count > 2 {
            allFramesTotalSize = rlpHeader.listValue[2].intValue
        }

        var paddingSize = 16 - (frameBodySize % 16)
        if paddingSize >= 16 {
            paddingSize = 0
        }

        let frameSize = 32 + frameBodySize + paddingSize + 16  // header || body || padding || body-mac

        guard data.count >= frameSize else {
            return nil
        }

        let frameBodyData = data.subdata(in: 32..<(frameSize - 16))
        let frameBodyMac = data.subdata(in: (frameSize - 16)..<frameSize)
        secrets.ingressMac.update(with: frameBodyData)

        let decryptedFrame: Data = decryptor.encrypt(frameBodyData)

        let rlpPacketType = RLP.decode(input: decryptedFrame)
        let packetType = rlpPacketType.intValue
        let packetTypeLength = rlpPacketType.lengthOfLengthBytes + rlpPacketType.length

        let payload = decryptedFrame.subdata(in: packetTypeLength..<frameBodySize)

        let ingressMac = secrets.ingressMac.digest()
        let updatedFrameBodyMac = helper.updateMac(mac: secrets.ingressMac, macKey: secrets.mac, data: ingressMac)

        guard updatedFrameBodyMac == frameBodyMac else {
            throw FrameCodecError.macMismatch
        }

        return Frame(type: packetType, payload: payload, size: frameSize, contextId: contextId, allFramesTotalSize: allFramesTotalSize)
    }

    func encodeFrame(frame: Frame) -> Data {
        // Header
        let packetType = RLP.encode(frame.type)
        let frameSize = frame.payloadSize + packetType.count

        var headerDataElements = [0]
        if frame.contextId > 0 {
            headerDataElements.append(frame.contextId)
        }
        if frame.allFramesTotalSize > 0 {
            headerDataElements.append(frame.allFramesTotalSize)
        }

        var header = helper.toThreeBytes(int: frameSize)
        header += RLP.encode(headerDataElements)
        header += Data(repeating: 0, count: 16 - header.count)

        let encryptedHeader = encryptor.encrypt(header)
        let headerMac = helper.updateMac(mac: secrets.egressMac, macKey: secrets.mac, data: encryptedHeader)

        // Body
        var frameData = packetType + frame.payload
        if frameSize % 16 > 0 {
            frameData += Data(repeating: 0, count: 16 - frameSize % 16)
        }

        let encryptedFrameData = encryptor.encrypt(frameData)
        secrets.egressMac.update(with: encryptedFrameData)

        let egressMac = secrets.egressMac.digest()
        let frameMac = helper.updateMac(mac: secrets.egressMac, macKey: secrets.mac, data: egressMac)

        return encryptedHeader + headerMac + encryptedFrameData + frameMac
    }

}
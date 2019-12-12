class FrameCodec {
    private let secrets: Secrets
    private let helper: IFrameCodecHelper
    private let encryptor: IAESCipher
    private let decryptor: IAESCipher  // AES in CTR encrypt gives the message back when you encrypt the cipher

    private var previousDecryptedHeader: Data?

    init(secrets: Secrets, helper: IFrameCodecHelper, encryptor: IAESCipher, decryptor: IAESCipher) {
        self.secrets = secrets
        self.helper = helper
        self.encryptor = encryptor
        self.decryptor = decryptor
    }

    func readFrame(from data: Data) throws -> Frame? {
        guard previousDecryptedHeader != nil || data.count >= Frame.minSize else {
            return nil
        }

        let decryptedHeader: Data

        if let previousDecryptedHeader = previousDecryptedHeader {
            decryptedHeader = previousDecryptedHeader
        } else {
            let header = data.subdata(in: 0..<16)
            let headerMac = data.subdata(in: 16..<32)
            let updatedMac = helper.updateMac(mac: secrets.ingressMac, macKey: secrets.mac, data: header)

            guard updatedMac == headerMac else {
                throw FrameCodecError.macMismatch
            }

            decryptedHeader = decryptor.process(header)
            previousDecryptedHeader = decryptedHeader
        }

        let frameBodySize = helper.fromThreeBytes(data: decryptedHeader.subdata(in: 0..<3))

        let rlpHeaderElements = try RLP.decode(input: decryptedHeader.subdata(in: 3..<decryptedHeader.count)).listValue()
        var contextId = -1
        if rlpHeaderElements.count > 1 {
            contextId = try rlpHeaderElements[1].intValue()
        }
        var allFramesTotalSize = -1
        if rlpHeaderElements.count > 2 {
            allFramesTotalSize = try rlpHeaderElements[2].intValue()
        }

        var paddingSize = 16 - (frameBodySize % 16)
        if paddingSize >= 16 {
            paddingSize = 0
        }

        let frameSize = 32 + frameBodySize + paddingSize + 16  // header || body || padding || body-mac

        guard data.count >= frameSize else {
            return nil
        }

        previousDecryptedHeader = nil

        let frameBodyData = data.subdata(in: 32..<(frameSize - 16))
        let frameBodyMac = data.subdata(in: (frameSize - 16)..<frameSize)
        secrets.ingressMac.update(with: frameBodyData)

        let decryptedFrame: Data = decryptor.process(frameBodyData)

        let rlpPacketType = try RLP.decode(input: decryptedFrame)
        let packetType = try rlpPacketType.intValue()
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

        let encryptedHeader = encryptor.process(header)
        let headerMac = helper.updateMac(mac: secrets.egressMac, macKey: secrets.mac, data: encryptedHeader)

        // Body
        var frameData = packetType + frame.payload
        if frameSize % 16 > 0 {
            frameData += Data(repeating: 0, count: 16 - frameSize % 16)
        }

        let encryptedFrameData = encryptor.process(frameData)
        secrets.egressMac.update(with: encryptedFrameData)

        let egressMac = secrets.egressMac.digest()
        let frameMac = helper.updateMac(mac: secrets.egressMac, macKey: secrets.mac, data: egressMac)

        return encryptedHeader + headerMac + encryptedFrameData + frameMac
    }

}

extension FrameCodec {

    enum FrameCodecError: Error {
        case macMismatch
    }

}

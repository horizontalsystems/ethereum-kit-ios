import BigInt

struct RLP {

    enum DecodeError: Error {
        case emptyData
        case invalidElementLength
        case invalidListValue
        case invalidIntValue
        case invalidBigIntValue
        case invalidStringValue
    }

    enum ElementType {
        case string
        case list
    }

    static func encode(_ element: Any) -> Data {
        switch element {
        case let list as [Any]:
            return encode(elements: list)

        case let bigInt as BigUInt:
            return encode(bigInt: bigInt)

        case let int as Int:
            return encode(bigInt: BigUInt(int))

        case let data as Data:
            return encode(data: data)

        case let string as String:
            return encode(string: string) ?? Data()

        default:
            return Data()
        }
    }

    static func decode(input: Data) throws -> RLPElement {
        guard input.count > 0 else {
            throw DecodeError.emptyData
        }

        guard let (offset, dataLen, type) = decode_length(input) else {
            throw DecodeError.invalidElementLength
        }

        var output: RLPElement;

        if type == .string {
            output = RLPElement(type: .string, length: dataLen, lengthOfLengthBytes: offset, dataValue: input.subdata(in: offset..<(offset + dataLen)), listValue: nil)
        } else {
            var value = [RLPElement]()

            let listData = input.subdata(in: offset..<(offset + dataLen))
            var listDataOffset = 0

            while listDataOffset < listData.count {
                let element = try decode(input: Data(listData.suffix(from: listDataOffset)))

                value.append(element)
                listDataOffset += element.length + element.lengthOfLengthBytes
            }

            output = RLPElement(type: .list, length: dataLen, lengthOfLengthBytes: offset, dataValue: input.subdata(in: 0..<(offset + dataLen)), listValue: value)
        }

        return output
    }

    private static func decode_length(_ input: Data) -> (Int, Int, ElementType)? {
        let length = input.count

        guard input.count > 0 else {
            return nil
        }

        let prefix = Int(input[0])

        if prefix <= 0x7f {
            return (0, 1, .string)

        } else if prefix <= 0xb7 && length > prefix - 0x80 {
            return (1, prefix - 0x80, .string)

        } else if prefix <= 0xbf && length > prefix - 0xb7,
                  let len = to_integer(input.subdata(in: 1..<(1 + prefix - 0xb7))),
                  length > prefix - 0xb7 + len {

            let lenOfStrLen = prefix - 0xb7
            if let strLen = to_integer(input.subdata(in: 1..<(1 + lenOfStrLen))) {
                return (1 + lenOfStrLen, strLen, .string)
            }

        } else if prefix <= 0xf7 && length > prefix - 0xc0 {
            let listLen = prefix - 0xc0
            return (1, listLen, .list)

        } else if prefix <= 0xff && length > prefix - 0xf7,
                  let len = to_integer(input.subdata(in: 1..<(1 + prefix - 0xf7))),
                  length > prefix - 0xf7 + len {

            let lenOfListLen = prefix - 0xf7
            if let listLen = to_integer(input.subdata(in: 1..<(1 + lenOfListLen))) {
                return (1 + lenOfListLen, listLen, .list)
            }

        }

        return nil
    }

    private static func to_integer(_ b: Data) -> Int? {
        let length = b.count

        guard length > 0 else {
            return nil
        }

        if length == 1 {
            return Int(b[0])
        } else {
            if let len = to_integer(b.subdata(in: 0..<(length - 1))) {
                return Int(b[length - 1]) + len * 256
            } else {
                return nil
            }
        }
    }

    private static func encode(data: Data) -> Data {
        if data.count == 1 && data[0] <= 0x7f {
            return data
        }

        var encoded = encodeHeader(size: UInt64(data.count), smallTag: 0x80, largeTag: 0xb7)
        encoded.append(data)
        return encoded
    }

    private static func encode(string: String) -> Data? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return encode(data: data)
    }

    private static func encode(bigInt: BigUInt) -> Data {
        let data = bigInt.serialize()
        if data.isEmpty {
            return Data([0x80])
        }
        return encode(data: data)
    }

    private static func encode(elements: [Any]) -> Data {
        var data = Data()
        for element in elements {
            data.append(encode(element))
        }

        var encodedData = encodeHeader(size: UInt64(data.count), smallTag: 0xc0, largeTag: 0xf7)
        encodedData.append(data)
        return encodedData
    }

    private static func encodeHeader(size: UInt64, smallTag: UInt8, largeTag: UInt8) -> Data {
        if size < 56 {
            return Data([smallTag + UInt8(size)])
        }

        let sizeData = putint(size)
        var encoded = Data()
        encoded.append(largeTag + UInt8(sizeData.count))
        encoded.append(contentsOf: sizeData)
        return encoded
    }

    private static func putint(_ i: UInt64) -> Data {
        switch i {
        case 0 ..< (1 << 8):
            return Data([UInt8(i)])
        case 0 ..< (1 << 16):
            return Data([
                UInt8(i >> 8),
                UInt8(truncatingIfNeeded: i)
                ])
        case 0 ..< (1 << 24):
            return Data([
                UInt8(i >> 16),
                UInt8(truncatingIfNeeded: i >> 8),
                UInt8(truncatingIfNeeded: i)
                ])
        case 0 ..< (1 << 32):
            return Data([
                UInt8(i >> 24),
                UInt8(truncatingIfNeeded: i >> 16),
                UInt8(truncatingIfNeeded: i >> 8),
                UInt8(truncatingIfNeeded: i)
                ])
        case 0 ..< (1 << 40):
            return Data([
                UInt8(i >> 32),
                UInt8(truncatingIfNeeded: i >> 24),
                UInt8(truncatingIfNeeded: i >> 16),
                UInt8(truncatingIfNeeded: i >> 8),
                UInt8(truncatingIfNeeded: i)
                ])
        case 0 ..< (1 << 48):
            return Data([
                UInt8(i >> 40),
                UInt8(truncatingIfNeeded: i >> 32),
                UInt8(truncatingIfNeeded: i >> 24),
                UInt8(truncatingIfNeeded: i >> 16),
                UInt8(truncatingIfNeeded: i >> 8),
                UInt8(truncatingIfNeeded: i)
                ])
        case 0 ..< (1 << 56):
            return Data([
                UInt8(i >> 48),
                UInt8(truncatingIfNeeded: i >> 40),
                UInt8(truncatingIfNeeded: i >> 32),
                UInt8(truncatingIfNeeded: i >> 24),
                UInt8(truncatingIfNeeded: i >> 16),
                UInt8(truncatingIfNeeded: i >> 8),
                UInt8(truncatingIfNeeded: i)
                ])
        default:
            return Data([
                UInt8(i >> 56),
                UInt8(truncatingIfNeeded: i >> 48),
                UInt8(truncatingIfNeeded: i >> 40),
                UInt8(truncatingIfNeeded: i >> 32),
                UInt8(truncatingIfNeeded: i >> 24),
                UInt8(truncatingIfNeeded: i >> 16),
                UInt8(truncatingIfNeeded: i >> 8),
                UInt8(truncatingIfNeeded: i)
            ])
        }
    }
}

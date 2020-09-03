import OpenSslKit
import UIExtensions

public class BloomFilter {
    private let filter: String

    init(filter: String) {
        self.filter = filter
    }

    private func codePointToInt(character: Character) -> UInt16? {
        let utf16Code = character.utf16
        let charCode = utf16Code[utf16Code.startIndex]

        if (charCode >= 48 && charCode <= 57) {
            /* ['0'..'9'] -> [0..9] */
            return charCode - 48
        }

        if (charCode >= 65 && charCode <= 70) {
            /* ['A'..'F'] -> [10..15] */
            return charCode - 55
        }

        if (charCode >= 97 && charCode <= 102) {
            /* ['a'..'f'] -> [10..15] */
            return charCode - 87
        }

        return nil
    }


    private func mayContain(element: Data) -> Bool {
        let hash = OpenSslKit.Kit.sha3(element)

        for i in 0..<3 {
            let uInt16Position = i * 2

            let bitPosition = ((UInt16(hash[uInt16Position]) << 8) + UInt16(hash[uInt16Position + 1])) & 2047

            let characterIndexInt = filter.count - 1 - Int(Float(bitPosition / 4).rounded(.down))
            let characterIndex = filter.index(filter.startIndex, offsetBy: characterIndexInt)

            guard let code = codePointToInt(character: filter[characterIndex]) else {
                return false
            }

            let offset: UInt16 = 1 << (bitPosition % 4)

            if ((code & offset) != offset) {
                return false
            }
        }

        return true
    }

    public func mayContain(contractAddress: Address) -> Bool {
        mayContain(element: contractAddress.raw)
    }

    func mayContain(userAddress: Address) -> Bool {
        mayContain(element: Data(count: 12) + userAddress.raw)
    }

}
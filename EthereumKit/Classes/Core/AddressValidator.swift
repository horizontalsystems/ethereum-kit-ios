import OpenSslKit

class AddressValidator {

    enum ValidationError: Error {
        case invalidChecksum
        case invalidAddressLength
        case invalidSymbols
        case wrongAddressPrefix
    }

    private static func isCheckSumAddress(hex: String) throws {
        let addressHash: String = OpenSslKit.Kit.sha3(hex.lowercased().data(using: .ascii)!).toRawHexString()
        for i in 0..<40 {
            let hashSymbol = character(addressHash, i)

            guard let int = Int(hashSymbol, radix: 16) else {
                throw ValidationError.invalidSymbols
            }
            if (int > 7 && character(hex, i).uppercased() != character(hex, i)) || (int < 8 && character(hex, i).lowercased() != character(hex, i)) {
                throw ValidationError.invalidChecksum
            }
        }
    }

    private static func character(_ str: String, _ i: Int) -> String {
        String(str[str.index(str.startIndex, offsetBy: i)])
    }

}

extension AddressValidator {

    static func validate(address: String) throws {
        guard address.hasPrefix("0x") else {
            throw ValidationError.wrongAddressPrefix
        }
        let hex = String(address.dropFirst(2))
        guard hex.count == 40 else {
            throw ValidationError.invalidAddressLength
        }
        let decimalDigits = CharacterSet.decimalDigits
        let lowerCasedHex = decimalDigits.union(CharacterSet(charactersIn: "abcdef"))
        let upperCasedHex = decimalDigits.union(CharacterSet(charactersIn: "ABCDEF"))
        let mixedHex = decimalDigits.union(CharacterSet(charactersIn: "abcdefABCDEF"))
        guard mixedHex.isSuperset(of: CharacterSet(charactersIn: hex)) else {
            throw ValidationError.invalidSymbols
        }
        if lowerCasedHex.isSuperset(of: CharacterSet(charactersIn: hex)) || upperCasedHex.isSuperset(of: CharacterSet(charactersIn: hex)) {
            return
        } else {
            try isCheckSumAddress(hex: hex)
        }
    }

}

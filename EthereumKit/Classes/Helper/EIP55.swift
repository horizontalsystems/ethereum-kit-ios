import OpenSslKit

// NOTE: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md

struct EIP55 {

    static func format(address: String) -> String {
        guard !address.isEmpty else {
            return address
        }

        let address = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address

        guard address == address.lowercased() || address == address.uppercased() else {
            return "0x" + address
        }

        let hash = OpenSslKit.Kit.sha3(address.lowercased().data(using: .ascii)!).hex

        return "0x" + zip(address, hash)
                .map { a, h -> String in
                    switch (a, h) {
                    case ("0", _), ("1", _), ("2", _), ("3", _), ("4", _), ("5", _), ("6", _), ("7", _), ("8", _), ("9", _):
                        return String(a)
                    case (_, "8"), (_, "9"), (_, "a"), (_, "b"), (_, "c"), (_, "d"), (_, "e"), (_, "f"):
                        return String(a).uppercased()
                    default:
                        return String(a).lowercased()
                    }
                }
                .joined()
    }

}

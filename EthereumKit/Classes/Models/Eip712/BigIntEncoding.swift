// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import BigInt

extension BigInt {
    /// Serializes the `BigInt` with the specified bit width.
    ///
    /// - Returns: the serialized data or `nil` if the number doesn't fit in the specified bit width.
    func serialize(bitWidth: Int) -> Data? {
        let valueData = twosComplement()
        if valueData.count > bitWidth {
            return nil
        }

        var data = Data()
        if sign == .plus {
            data.append(Data(repeating: 0, count: bitWidth - valueData.count))
        } else {
            data.append(Data(repeating: 255, count: bitWidth - valueData.count))
        }
        data.append(valueData)
        return data
    }

    // Computes the two's complement for a `BigInt` with 256 bits
    private func twosComplement() -> Data {
        if sign == .plus {
            return magnitude.serialize()
        }

        let serializedLength = magnitude.serialize().count
        let max = BigUInt(1) << (serializedLength * 8)
        return (max - magnitude).serialize()
    }
}

import Foundation
import OpenSslKit

class NameHash {

    static func nameHash(name: String) -> String {
        var hash = Data.init(count: 32)
        let labels = name.components(separatedBy: ".")
        for label in labels.reversed() {
            hash.append(Sha3.keccak256(label.data))
            hash = Sha3.keccak256(hash)
        }
        return hash.toHexString()
    }

}

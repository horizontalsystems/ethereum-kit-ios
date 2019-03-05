import Foundation

class ECPoint {

    var x: Data
    var y: Data

    init(nodeId: Data) {
        self.x = nodeId.subdata(in: 0..<32)
        self.y = nodeId.subdata(in: 32..<64)
    }

    public func toString() -> String {
        return "[X: \(x.toHexString()); Y: \(y.toHexString())]"
    }

    func uncompressed() -> Data {
        return Data(hex: "04") + x + y
    }
}
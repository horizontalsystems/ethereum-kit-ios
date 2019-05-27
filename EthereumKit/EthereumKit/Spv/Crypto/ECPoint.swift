class ECPoint {
    let x: Data
    let y: Data

    init(nodeId: Data) {
        self.x = nodeId.subdata(in: 0..<32)
        self.y = nodeId.subdata(in: 32..<64)
    }

    func toString() -> String {
        return "[X: \(x.toHexString()); Y: \(y.toHexString())]"
    }

    func uncompressed() -> Data {
        return Data([4]) + x + y
    }

}

class ECKey {
    let privateKey: Data
    let publicKeyPoint: ECPoint

    init(privateKey: Data, publicKeyPoint: ECPoint) {
        self.privateKey = privateKey
        self.publicKeyPoint = publicKeyPoint
    }

    func toString() -> String {
        return "[privateKey: \(privateKey.toHexString()); publicKey: \(publicKeyPoint.toString())]"
    }

}

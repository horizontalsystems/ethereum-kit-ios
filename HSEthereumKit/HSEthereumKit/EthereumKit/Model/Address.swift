struct Address {
    let data: Data

    var string: String {
        return EIP55.encode(data)
    }

    init(data: Data) {
        self.data = data
    }

    init(string: String) {
        data = Data(hex: string.stripHexPrefix())
    }

}

extension Data {

    func sortsBefore(address: Data) -> Bool {
        toHexString().lowercased() < address.toHexString().lowercased()
    }

}

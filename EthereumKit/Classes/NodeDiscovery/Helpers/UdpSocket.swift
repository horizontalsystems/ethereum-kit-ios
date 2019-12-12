import Socket

class UdpSocket: IUdpSocket {
    private let socket: Socket

    init() throws {
        socket = try Socket.create(type: .datagram, proto: .udp)
    }

    func setReadTimeout(value: UInt) throws {
        try socket.setReadTimeout(value: value)
    }

    @discardableResult func write(from data: Data, to address: Socket.Address) throws -> Int {
        return try socket.write(from:data, to: address)
    }

    func readDatagram() throws -> (bytesRead: Int, data: Data) {
        var data = Data()
        let (count, _) = try socket.readDatagram(into: &data)
        return (count, data)
    }

    func createAddress(host: String, port: Int32) -> Socket.Address? {
        return Socket.createAddress(for: host, on: Int32(port))
    }

}

import Socket

enum UDPClientError: Error {
    case cantCreateAddress
    case timeout
}

class UdpClient: IUdpClient {
    private let socket: IUdpSocket
    private let timeoutInterval: TimeInterval
    private let queue: DispatchQueue

    let node: Node
    private(set) var noResponse = true

    weak var delegate: IUdpClientDelegate?
    var id: Data { return node.id }

    init(socket: IUdpSocket? = nil, node: Node, timeoutInterval: TimeInterval, queue: DispatchQueue = DispatchQueue.global(qos: .userInteractive)) throws {
        try self.socket = socket ?? UdpSocket()
        self.node = node
        self.timeoutInterval = timeoutInterval
        self.queue = queue
    }

    func listen() {
        do {
            try socket.setReadTimeout(value: UInt(timeoutInterval))
        } catch {
            delegate?.didStop(self, by: error)
            return
        }

        queue.async {
            while true {
                do {
                    let (bytesRead, data) = try self.socket.readDatagram()

                    //timeout brake
                    guard bytesRead != 0 else {
                        self.delegate?.didStop(self, by: UDPClientError.timeout)
                        return
                    }
                    self.noResponse = false
                    try self.delegate?.didReceive(self, data: data)
                } catch {
                    self.delegate?.didStop(self, by: error)
                    //separate errors if needed
                }
            }
        }
    }

    func send(_ data: Data) throws {
        guard let address = socket.createAddress(host: node.host, port: Int32(node.discoveryPort)) else {
            throw UDPClientError.cantCreateAddress
        }

        try socket.write(from: data, to: address)
    }

}

extension UdpClient: Equatable {

    public static func ==(lhs: UdpClient, rhs: UdpClient) -> Bool {
        return lhs.id == rhs.id
    }

}
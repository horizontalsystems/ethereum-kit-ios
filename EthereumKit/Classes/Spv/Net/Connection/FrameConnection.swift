import HsToolKit

class FrameConnection {
    weak var delegate: IFrameConnectionDelegate?

    private let connection: IConnection

    init(connection: IConnection) {
        self.connection = connection
    }
}

extension FrameConnection: IFrameConnection {

    func connect() {
        connection.connect()
    }

    func disconnect(error: Error?) {
        connection.disconnect(error: error)
    }

    func send(packetType: Int, payload: Data) {
        let frame = Frame(type: packetType, payload: payload, contextId: -1, allFramesTotalSize: -1)
        connection.send(frame: frame)
    }

    var logName: String {
        return connection.logName
    }

}

extension FrameConnection: IConnectionDelegate {

    func didConnect() {
        delegate?.didConnect()
    }

    func didDisconnect(error: Error?) {
        delegate?.didDisconnect(error: error)
    }

    func didReceive(frame: Frame) {
        delegate?.didReceive(packetType: frame.type, payload: frame.payload)
    }

}

extension FrameConnection {

    static func instance(connectionKey: ECKey, node: Node, logger: Logger? = nil) -> FrameConnection {
        let connection = Connection(connectionKey: connectionKey, node: node, logger: logger)
        let frameConnection = FrameConnection(connection: connection)

        connection.delegate = frameConnection

        return frameConnection
    }

}

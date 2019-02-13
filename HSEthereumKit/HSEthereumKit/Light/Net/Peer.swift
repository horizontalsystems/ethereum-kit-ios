import Foundation

class Peer {

    enum PeerError: Error {
        case peerDoesNotSupportLES
    }

    private let connection: IPeerConnection
    private let myKey: ECKey
    private let myListenPort: UInt32 = 30303

    init(nodeId: String, host: String, port: Int, discPort: Int) {
        myKey = ECKey(
                privateKey: Data(hex: "0000000000000000000000000000000000000000000000000000000000000000"),
                publicKeyPoint: ECPoint(nodeId: Data(hex: "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"))
        )

        connection = Connection(nodeId: nodeId, host: host, port: port, discPort: discPort)
        connection.delegate = self
    }

    private func sendStatus() {
    }

    private func handle(message: IMessage) throws {
        switch message {
        case let helloMessage as HelloMessage: handle(message: helloMessage)
        case let pingMessage as PingMessage: handle(message: pingMessage)
        case let pongMessage as PongMessage: handle(message: pongMessage)
        case let disconnectMessage as DisconnectMessage: handle(message: disconnectMessage)
        case let statusMessage as StatusMessage: handle(message: statusMessage)
        default: break
        }
    }

    // Devp2p messages

    func handle(message: HelloMessage) {
        print("<<< HELLO: \(message.toString())")
    }

    func handle(message: PingMessage) {
        print("<<< PING: \(message.toString())")

        let message = PongMessage()
        connection.send(message: message)
    }

    func handle(message: PongMessage) {
        print("<<< PONG: \(message.toString())")
    }

    func handle(message: DisconnectMessage) {
        print("<<< DISCONNECT: \(message.toString())")
    }


    // LES Messages

    private func validatePeerVersion(message: StatusMessage) throws {
        //        guard let startHeight = message.startHeight, startHeight > 0 else {
        //            throw PeerError.peerBestBlockIsLessThanOne
        //        }
        //
        //        guard startHeight >= localBestBlockHeight else {
        //            throw PeerError.peerHasExpiredBlockChain(localHeight: localBestBlockHeight, peerHeight: startHeight)
        //        }
        //
        //        guard message.hasBlockChain(network: network) else {
        //            throw PeerError.peerNotFullNode
        //        }
        //
        //        guard message.supportsBloomFilter(network: network) else {
        //            throw PeerError.peerDoesNotSupportBloomFilter
        //        }
    }

    private func handle(message: StatusMessage) {
        print("<<< STATUS: \(message.toString())")
    }

}

extension Peer {

    func connect() {
        connection.connect()
    }

    func disconnect(error: Error? = nil) {
//        self.connection.disconnect(error: error)
    }

}

extension Peer: PeerConnectionDelegate {

    func connectionEstablished() {
        let helloMessage = HelloMessage(peerId: myKey.publicKeyPoint.x + myKey.publicKeyPoint.y, port: myListenPort)

        connection.send(message: helloMessage)
    }

    func connectionKey() -> ECKey {
        return myKey
    }

    func connectionDidDisconnect(withError error: Error?) {
        print("Disconnected ...")
    }

    func connection(didReceiveMessage message: IMessage) {
        do {
            try self.handle(message: message)
        } catch {
            self.disconnect(error: error)
        }
    }

}

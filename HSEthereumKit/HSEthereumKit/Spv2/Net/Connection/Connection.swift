import Foundation

class Connection: NSObject {
    enum PeerConnectionError: Error {
        case connectionClosedWithUnknownError
        case connectionClosedByPeer
        case encryptionHandshakeError
    }

    private let bufferSize = 4096
    private let interval = 1.0

    let nodeId: Data
    let host: String
    let port: UInt32
    let discPort: UInt32

    weak var delegate: IConnectionDelegate?
    private var handshake: EncryptionHandshake?
    private var frameCodec: FrameCodec?
    private let frameHandler: IFrameHandler
    private let factory: IFactory
    private let logger: Logger?

    private var runLoop: RunLoop?
    private var readStream: Unmanaged<CFReadStream>?
    private var writeStream: Unmanaged<CFWriteStream>?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var packets: Data = Data()


    var connected: Bool = false
    var handshakeSent: Bool = false

    var logName: String {
        return "\(nodeId.toHexString())@\(host):\(port)'"
    }

    init(node: Node, factory: IFactory = Factory.shared, logger: Logger? = nil) {
        self.nodeId = node.id
        self.host = node.host
        self.port = UInt32(node.port)
        self.discPort = UInt32(node.discoveryPort)

        self.factory = factory
        self.logger = logger
        frameHandler = FrameHandler()
    }

    deinit {
        disconnect()
    }

    private func connectAsync() {
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host as CFString, port, &readStream, &writeStream)
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream?.delegate = self
        outputStream?.delegate = self

        inputStream?.schedule(in: .current, forMode: .commonModes)
        outputStream?.schedule(in: .current, forMode: .commonModes)

        inputStream?.open()
        outputStream?.open()

        RunLoop.current.run()
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }

        while stream.hasBytesAvailable {
            let numberOfBytesRead = stream.read(buffer, maxLength: bufferSize)
            if numberOfBytesRead <= 0 {
                if let _ = stream.streamError {
                    break
                }
            } else {
                packets += Data(bytesNoCopy: buffer, count: numberOfBytesRead, deallocator: .none)
            }
        }

        if let handshake = handshake {
            guard let eciesMessage = ECIESEncryptedMessage(data: packets) else {
                return
            }

            do {
                let secrets = try handshake.extractSecrets(from: eciesMessage)
                packets = Data(packets.dropFirst(eciesMessage.encoded().count))

                frameCodec = factory.frameCodec(secrets: secrets)
                self.handshake = nil

                delegate?.connectionEstablished()
            } catch {
                disconnect(error: PeerConnectionError.encryptionHandshakeError)
            }

            return
        }

        guard let frameCodec = frameCodec else {
            return
        }

        do {
            while let frame = try frameCodec.readFrame(from: packets) {
                packets = Data(packets.dropFirst(frame.size))
                frameHandler.add(frame: frame)

                if let message = try frameHandler.getMessage() {
                    delegate?.connection(didReceiveMessage: message)
                }
            }
        } catch {
            disconnect(error: error)
        }
    }

    func initiateHandshake() {
        guard !handshakeSent else {
            return
        }

        guard let delegate = self.delegate else {
            log("Can't initiate handshake without delegate")
            return
        }

        handshakeSent = true
        let handshake = factory.encryptionHandshake(myKey: delegate.connectionKey(), publicKey: nodeId)

        let authMessagePacket: Data!
        do {
            authMessagePacket = try handshake.createAuthMessage()
        } catch {
            disconnect(error: error)
            return
        }

        self.handshake = handshake

        sendPackets(data: authMessagePacket)
    }

    private func sendPackets(data: Data) {
        _ = data.withUnsafeBytes {
            outputStream?.write($0, maxLength: data.count)
        }
    }

    private func log(_ msg: String) {
        print(msg)
    }

}


extension Connection: IConnection {

    func connect() {
        if runLoop == nil {
            DispatchQueue.global(qos: .userInitiated).async {
                self.runLoop = .current
                self.connectAsync()
            }
        } else {
            log("ALREADY CONNECTED")
        }
    }

    func disconnect(error: Error? = nil) {
        guard readStream != nil && readStream != nil else {
            return
        }

        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: .current, forMode: .commonModes)
        outputStream?.remove(from: .current, forMode: .commonModes)
        readStream = nil
        writeStream = nil
        runLoop = nil
        connected = false

        delegate?.connectionDidDisconnect(withError: error)

        logger?.verbose("DISCONNECTED: \(error?.localizedDescription ?? "nil")")
    }

    func register(capabilities: [Capability]) {
        frameHandler.register(capabilities: capabilities)
    }

    func send(message: IMessage) {
        logger?.verbose(">>> \(message.toString())")

        guard let frameCodec = self.frameCodec else {
            log("ERROR: trying to send message before RLPx handshake")
            return
        }

        let frames = frameHandler.getFrames(from: message)

        for frame in frames {
            let encodedFrame = frameCodec.encodeFrame(frame: frame)
            sendPackets(data: encodedFrame)
        }
    }

}


extension Connection: StreamDelegate {

    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch stream {
        case let stream as InputStream:
            switch eventCode {
            case .openCompleted:
                logger?.verbose("CONNECTION ESTABLISHED")
                connected = true
                break
            case .hasBytesAvailable:
                readAvailableBytes(stream: stream)
            case .hasSpaceAvailable:
                break
            case .errorOccurred:
                log("IN ERROR OCCURRED")
                if connected {
                    // If connected, then error is related not to peer, but to network
                    disconnect()
                } else {
                    disconnect(error: PeerConnectionError.connectionClosedWithUnknownError)
                }
            case .endEncountered:
                log("IN CLOSED")
                disconnect(error: PeerConnectionError.connectionClosedByPeer)
            default:
                break
            }
        case _ as OutputStream:
            switch eventCode {
            case .openCompleted:
                break
            case .hasBytesAvailable:
                break
            case .hasSpaceAvailable:
                initiateHandshake()
            case .errorOccurred:
                log("OUT ERROR OCCURRED")
                disconnect()
            case .endEncountered:
                log("OUT CLOSED")
                disconnect()
            default:
                break
            }
        default:
            break
        }
    }

}

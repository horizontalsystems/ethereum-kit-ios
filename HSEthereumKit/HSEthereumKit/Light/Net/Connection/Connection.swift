import Foundation

class Connection: NSObject {
    enum PeerConnectionError: Error {
        case connectionClosedWithUnknownError
        case connectionClosedByPeer
        case encryptionHandshakeError
    }

    private let bufferSize = 8192
    private let interval = 1.0

    let nodeId: String
    let host: String
    let port: UInt32
    let discPort: UInt32

    weak var delegate: PeerConnectionDelegate?
    private var handshake: EncryptionHandshake?
    private var frameCodec: FrameCodec?

    private var runLoop: RunLoop?
    private var readStream: Unmanaged<CFReadStream>?
    private var writeStream: Unmanaged<CFWriteStream>?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var packets: Data = Data()


    var connected: Bool = false
    var handshakeSent: Bool = false

    var logName: String {
        return "\(nodeId)@\(host):\(port)'";
    }

    init(nodeId: String, host: String, port: Int, discPort: Int) {
        self.nodeId = nodeId
        self.host = host
        self.port = UInt32(port)
        self.discPort = UInt32(discPort)
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

        if packets.count >= 0 {
            if let handshake = handshake {
                do {
                    let secrets = try handshake.extractSecretsFromResponse(in: packets)
                    packets = Data(packets.dropFirst(handshake.authAckMessagePacket.count))

                    frameCodec = FrameCodec(secrets: secrets)
                    self.handshake = nil

                    delegate?.connectionEstablished()
                } catch {
                    print(error)
                    disconnect(error: PeerConnectionError.encryptionHandshakeError)
                }

                return
            }

            if let frameCode = frameCodec {
                let frames = frameCode.readFrames(from: packets)

                if frames.count > 0 {
                    packets = Data(packets.dropFirst(frames.reduce(0) { $0 + $1.size }))
                }

                if let message = Frame.framesToMessage(frames: frames) {
                    delegate?.connection(didReceiveMessage: message)
                }
            }

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

        let handshake = EncryptionHandshake(myKey: delegate.connectionKey(), publicKeyPoint: ECPoint(nodeId: Data(hex: nodeId)))
        handshake.createAuthMessage()

        self.handshake = handshake

        sendPackets(data: handshake.authMessagePacket)
    }

    private func sendPackets(data: Data) {
        print(">>>>>> \(data.toHexString())")

        _ = data.withUnsafeBytes {
            outputStream?.write($0, maxLength: data.count)
        }
    }

    private func log(_ msg: String) {
        print(msg)
    }

}


extension Connection: IPeerConnection {

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

        log("DISCONNECTED")
    }

    func send(message: IMessage) {
        print(">>> \(type(of: message))")

        guard let frameCodec = self.frameCodec else {
            log("trying to send message before RLPx handshake")
            return
        }

        let frame = Frame(message: message)
        let encodedFrame = frameCodec.encodeFrame(frame: frame)

        sendPackets(data: encodedFrame)
    }

}


extension Connection: StreamDelegate {

    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch stream {
        case let stream as InputStream:
            switch eventCode {
            case .openCompleted:
                log("CONNECTION ESTABLISHED")
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

protocol PeerConnectionDelegate: class {
    func connectionEstablished()
    func connectionKey() -> ECKey
    func connectionDidDisconnect(withError error: Error?)
    func connection(didReceiveMessage message: IMessage)
}

protocol IPeerConnection: class {
    var delegate: PeerConnectionDelegate? { get set }
    var logName: String { get }
    func connect()
    func disconnect(error: Error?)
    func send(message: IMessage)
}


import RxSwift
import Starscream
import BigInt
import HsToolKit

class WebSocketSyncer {
    weak var delegate: IRpcSyncerDelegate?

    private let address: Address
    private let socket: IWebSocket
    private var logger: Logger?

    private var isSubscribedToNewHeads = false

    private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                delegate?.didUpdate(syncState: syncState)
            }
        }
    }

    private init(address: Address, socket: IWebSocket, logger: Logger? = nil) {
        self.address = address
        self.socket = socket
        self.logger = logger
    }

    private func fetchLastBlockHeight() {
        socket.send(
                rpc: BlockNumberJsonRpc(),
                onSuccess: { [weak self] lastBlockHeight in
                    self?.delegate?.didUpdate(lastBlockHeight: lastBlockHeight)
                    self?.fetchBalance()
                },
                onError: { [weak self] error in
                    self?.onFailSync(error: error)
                }
        )
    }

    private func fetchBalance() {
        socket.send(
                rpc: GetBalanceJsonRpc(address: address, defaultBlockParameter: .latest),
                onSuccess: { [weak self] balance in
                    self?.delegate?.didUpdate(balance: balance)
                    self?.syncState = .synced
                },
                onError: { [weak self] error in
                    self?.onFailSync(error: error)
                }
        )
    }

    private func subscribeToNewHeads() {
        socket.subscribe(
                subscription: NewHeadsRpcSubscription(),
                onSuccess: { [weak self] in
                    self?.isSubscribedToNewHeads = true
                },
                onError: { [weak self] error in
                    self?.onFailSync(error: error)
                },
                successHandler: { [weak self] header in
                    self?.delegate?.didUpdate(lastBlockLogsBloom: header.logsBloom)
                    self?.delegate?.didUpdate(lastBlockHeight: header.number)
                    self?.fetchBalance()
                },
                errorHandler: { [weak self] error in
                    self?.logger?.error("NewHeads Handle Failed: \(error)")
                }
        )
    }

    private func onFailSync(error: Error) {
        syncState = .notSynced(error: error)
//        socket.disconnect()
    }

}

extension WebSocketSyncer: IWebSocketDelegate {

    func didConnect() {
        fetchLastBlockHeight()
        subscribeToNewHeads()
    }

    func didDisconnect(error: Error) {
        isSubscribedToNewHeads = false
        syncState = .notSynced(error: error)
    }

}

extension WebSocketSyncer: IRpcSyncer {

    var source: String {
        "WebSocket Infura"
    }

    func start() {
        syncState = .syncing(progress: nil)
        socket.connect()
    }

    func stop(error: Error) {
        socket.disconnect(error: error)
        syncState = .notSynced(error: error)
    }

    func refresh() {
    }

    func single<T>(rpc: JsonRpc<T>) -> Single<T> {
        Single<T>.create { [weak self] observer in
            self?.socket.send(
                    rpc: rpc,
                    onSuccess: { value in
                        observer(.success(value))
                    },
                    onError: { error in
                        observer(.error(error))
                    }
            )

            return Disposables.create()
        }
    }

}

extension WebSocketSyncer {

    enum ParseError: Error {
        case invalidJson(value: Any)
        case noBlockNumber(result: [String: Any])
    }

}

extension WebSocketSyncer {

    static func instance(address: Address, socket: IWebSocket, logger: Logger? = nil) -> WebSocketSyncer {
        let syncer = WebSocketSyncer(address: address, socket: socket, logger: logger)
        socket.delegate = syncer
        return syncer
    }

}

// https://eips.ethereum.org/EIPS/eip-137#namehash-algorithm

import Foundation
import HsToolKit
import RxSwift

public class ENSProvider {
    private static let registryAddress = try! Address(hex: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    private let rpcApiProvider: IRpcApiProvider

    init(rpcApiProvider: IRpcApiProvider) {
        self.rpcApiProvider = rpcApiProvider
    }

    private func resolve(name: String, level: Level) -> Single<Address> {
        let nameHash = NameHash.nameHash(name: name)
        let data = ResolverMethod(hash: nameHash, method: level.name).encodedABI()
        let rpc = RpcBlockchain.callRpc(contractAddress: level.address, data: data, defaultBlockParameter: .latest)

        return rpcApiProvider.single(rpc: rpc)
                .flatMap { data -> Single<Address> in
                    do {
                        let address = data.prefix(32).suffix(20).toHexString()
                        return try Single.just(Address(hex: address))
                    } catch {
                        return Single.error(error)
                    }
                }
    }

}

extension ENSProvider {

    public func address(domain: String) -> Single<Address> {
        resolve(name: domain, level: .resolver)
                .flatMap { resolverAddress in
                    self.resolve(name: domain, level: .addr(resolver: resolverAddress))
                            .catchError { error in
                                Single.error(ResolveError.noAnyAddress)
                            }
                }.catchError { error in
                    Single.error(ResolveError.noAnyResolver)
                }
    }

}

extension ENSProvider {

    class ResolverMethod: ContractMethod {
        private let hash: String
        private let method: String

        init(hash: String, method: String) {
            self.hash = hash
            self.method = method
        }

        override var methodSignature: String {
            "\(method)(bytes32)"
        }

        override var arguments: [Any] {
            [hash]
        }
    }

}

extension ENSProvider {

    enum Level {
        case resolver
        case addr(resolver: Address)

        var name: String {
            switch self {
            case .resolver: return "resolver"
            case .addr: return "addr"
            }
        }

        var address: Address {
            switch self {
            case .resolver: return ENSProvider.registryAddress
            case .addr(let address): return address
            }
        }
    }

}

extension ENSProvider {

    public enum ResolveError: Error {
        case noAnyResolver
        case noAnyAddress
    }

    public enum RpcSourceError: Error {
        case websocketNotSupported
    }

}

extension ENSProvider {

    public static func instance(rpcSource: RpcSource, minLogLevel: Logger.Level = .error) throws -> ENSProvider {
        let logger = Logger(minLogLevel: minLogLevel)
        let networkManager = NetworkManager(logger: logger)
        let rpcApiProvider: IRpcApiProvider

        switch rpcSource {
        case let .http(urls, auth):
            rpcApiProvider = NodeApiProvider(networkManager: networkManager, urls: urls, auth: auth)
        case .webSocket:
            throw RpcSourceError.websocketNotSupported
        }

        return ENSProvider(rpcApiProvider: rpcApiProvider)
    }

}

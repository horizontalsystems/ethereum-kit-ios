import Foundation
import BigInt
import RxSwift
import HsToolKit

public class Eip1155Provider {
    private let rpcApiProvider: IRpcApiProvider

    init(rpcApiProvider: IRpcApiProvider) {
        self.rpcApiProvider = rpcApiProvider
    }

}

extension Eip1155Provider {

    public func getBalanceOf(contractAddress: Address, tokenId: BigUInt, address: Address) -> Single<BigUInt> {
        let data = BalanceOfMethod(owner: address, tokenId: tokenId).encodedABI()
        let rpc = RpcBlockchain.callRpc(contractAddress: contractAddress, data: data, defaultBlockParameter: .latest)

        return rpcApiProvider.single(rpc: rpc)
                .flatMap { data -> Single<BigUInt> in
                    guard let value = BigUInt(data.prefix(32).hex, radix: 16) else {
                        return Single.error(BalanceError.invalidHex)
                    }

                    return Single.just(value)
                }
    }

}

extension Eip1155Provider {

    class BalanceOfMethod: ContractMethod {
        private let owner: Address
        private let tokenId: BigUInt


        init(owner: Address, tokenId: BigUInt) {
            self.owner = owner
            self.tokenId = tokenId
        }

        override var methodSignature: String {
            "balanceOf(address,uint256)"
        }
        override var arguments: [Any] {
            [owner, tokenId]
        }
    }

}

extension Eip1155Provider {

    public enum BalanceError: Error {
        case invalidHex
    }

    public enum RpcSourceError: Error {
        case websocketNotSupported
    }

}

extension Eip1155Provider {

    public static func instance(rpcSource: RpcSource, minLogLevel: Logger.Level = .error) throws -> Eip1155Provider {
        let logger = Logger(minLogLevel: minLogLevel)
        let networkManager = NetworkManager(logger: logger)
        let rpcApiProvider: IRpcApiProvider

        switch rpcSource {
        case let .http(urls, auth):
            rpcApiProvider = NodeApiProvider(networkManager: networkManager, urls: urls, auth: auth)
        case .webSocket:
            throw RpcSourceError.websocketNotSupported
        }

        return Eip1155Provider(rpcApiProvider: rpcApiProvider)
    }

}

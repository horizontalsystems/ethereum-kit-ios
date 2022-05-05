import Foundation
import BigInt
import RxSwift

public class Eip1155Provider {
    private let evmKit: EthereumKit.Kit

    public init(evmKit: EthereumKit.Kit) {
        self.evmKit = evmKit
    }

}

extension Eip1155Provider {

    public func getBalanceOf(contractAddress: Address, tokenId: BigUInt, address: Address) -> Single<BigUInt> {
        evmKit.call(contractAddress: contractAddress, data: BalanceOfMethod(owner: address, tokenId: tokenId).encodedABI())
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

}

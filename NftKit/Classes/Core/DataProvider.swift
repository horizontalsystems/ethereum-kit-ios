import EthereumKit
import RxSwift
import BigInt

class DataProvider {
    private let evmKit: EthereumKit.Kit

    init(evmKit: EthereumKit.Kit) {
        self.evmKit = evmKit
    }

}

extension DataProvider {

    func getEip721Owner(contractAddress: Address, tokenId: BigUInt) -> Single<Address> {
        evmKit.call(contractAddress: contractAddress, data: Eip721OwnerOfMethod(tokenId: tokenId).encodedABI())
                .map { Address(raw: $0) }
    }

    func getEip1155Balance(contractAddress: Address, owner: Address, tokenId: BigUInt) -> Single<Int> {
        evmKit.call(contractAddress: contractAddress, data: Eip1155BalanceOfMethod(owner: owner, tokenId: tokenId).encodedABI())
                .flatMap { data -> Single<Int> in
                    guard let value = BigUInt(data.prefix(32).hex, radix: 16) else {
                        return Single.error(ContractCallError.invalidBalanceData)
                    }

                    return Single.just(Int(value))
                }
    }

}

extension DataProvider {

    enum ContractCallError: Error {
        case invalidBalanceData
    }

}

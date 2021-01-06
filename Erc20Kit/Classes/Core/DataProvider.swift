import EthereumKit
import RxSwift
import BigInt

class DataProvider {
    private let ethereumKit: EthereumKit.Kit

    init(ethereumKit: EthereumKit.Kit) {
        self.ethereumKit = ethereumKit
    }

}

extension DataProvider: IDataProvider {

    func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt> {
        ethereumKit.call(contractAddress: contractAddress, data: BalanceOfMethod(owner: address).encodedABI())
                .flatMap { data -> Single<BigUInt> in
                    guard let value = BigUInt(data.hex, radix: 16) else {
                        return Single.error(Erc20Kit.TokenError.invalidHex)
                    }

                    return Single.just(value)
                }
    }

}

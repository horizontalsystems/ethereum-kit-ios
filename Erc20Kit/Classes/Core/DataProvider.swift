import EthereumKit
import RxSwift
import BigInt

public class DataProvider {
    private let ethereumKit: EthereumKit.Kit

    public init(ethereumKit: EthereumKit.Kit) {
        self.ethereumKit = ethereumKit
    }

}

extension DataProvider: IDataProvider {

    public func getBalance(contractAddress: Address, address: Address) -> Single<BigUInt> {
        ethereumKit.call(contractAddress: contractAddress, data: BalanceOfMethod(owner: address).encodedABI())
                .flatMap { data -> Single<BigUInt> in
                    guard let value = BigUInt(data.prefix(32).hex, radix: 16) else {
                        return Single.error(Erc20Kit.TokenError.invalidHex)
                    }

                    return Single.just(value)
                }
    }

}

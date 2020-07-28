import RxSwift
import BigInt
import EthereumKit
import OpenSslKit

class AllowanceManager {
    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let contractAddress: Address
    private let address: Address

    init(ethereumKit: EthereumKit.Kit, contractAddress: Address, address: Address) {
        self.ethereumKit = ethereumKit
        self.contractAddress = contractAddress
        self.address = address
    }

    private func approveMethod(spenderAddress: Address, amount: BigUInt) -> ContractMethod {
        ContractMethod(name: "approve", arguments: [
            .address(spenderAddress),
            .uint256(amount)
        ])
    }

    func allowanceSingle(spenderAddress: Address) -> Single<BigUInt> {
        let method = ContractMethod(name: "allowance", arguments: [
            .address(address),
            .address(spenderAddress)
        ])

        return ethereumKit.call(contractAddress: contractAddress, data: method.encodedData)
                .map { data in
                    BigUInt(data[0...31])
                }
    }

    func estimateApproveSingle(spenderAddress: Address, amount: BigUInt, gasPrice: Int) -> Single<Int> {
        ethereumKit.estimateGas(
                to: contractAddress,
                amount: nil,
                gasPrice: gasPrice,
                data: approveMethod(spenderAddress: spenderAddress, amount: amount).encodedData
        )
    }

    func approveSingle(spenderAddress: Address, amount: BigUInt, gasLimit: Int, gasPrice: Int) -> Single<String> {
        ethereumKit.sendSingle(
                        address: contractAddress,
                        value: 0,
                        transactionInput: approveMethod(spenderAddress: spenderAddress, amount: amount).encodedData,
                        gasPrice: gasPrice,
                        gasLimit: gasLimit
                )
                .map { txInfo in
                    txInfo.hash
                }
    }

}

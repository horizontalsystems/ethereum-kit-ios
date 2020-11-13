import RxSwift
import BigInt
import EthereumKit
import OpenSslKit

enum AllowanceParsingError: Error {
    case notFound
}

class AllowanceManager {
    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let storage: ITransactionStorage
    private let contractAddress: Address
    private let address: Address

    init(ethereumKit: EthereumKit.Kit, storage: ITransactionStorage, contractAddress: Address, address: Address) {
        self.ethereumKit = ethereumKit
        self.storage = storage
        self.contractAddress = contractAddress
        self.address = address
    }

    func allowanceSingle(spenderAddress: Address, defaultBlockParameter: DefaultBlockParameter) -> Single<BigUInt> {
        let data = AllowanceMethod(owner: address, spender: spenderAddress).encodedABI()

        return ethereumKit.call(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
                .map { data in
                    BigUInt(data[0...31])
                }
    }

    func approveTransactionData(spenderAddress: Address, amount: BigUInt) -> TransactionData {
        TransactionData(
                to: contractAddress,
                value: BigUInt.zero,
                input: ApproveMethod(spender: spenderAddress, value: amount).encodedABI()
        )
    }

    func approveSingle(spenderAddress: Address, amount: BigUInt, gasLimit: Int, gasPrice: Int) -> Single<Transaction> {
        let approveMethod = ApproveMethod(spender: spenderAddress, value: amount)

        return ethereumKit.sendSingle(
                address: contractAddress,
                value: BigUInt.zero,
                transactionInput: ApproveMethod(spender: spenderAddress, value: amount).encodedABI(),
                gasPrice: gasPrice,
                gasLimit: gasLimit
        ).flatMap { transactionWithInternal in
            guard let approve = approveMethod.erc20Transactions(ethTx: transactionWithInternal.transaction).first else {
                return Single.error(AllowanceParsingError.notFound)
            }
            return Single.just(approve)
        }.do(onSuccess: { [weak self] transaction in
            self?.storage.save(transactions: [transaction])
        })
    }

}

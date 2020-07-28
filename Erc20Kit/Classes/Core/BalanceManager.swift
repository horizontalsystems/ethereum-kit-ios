import EthereumKit
import RxSwift
import BigInt

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let disposeBag = DisposeBag()

    private let contractAddress: Address
    private let address: Address
    private var storage: ITokenBalanceStorage
    private let dataProvider: IDataProvider

    init(contractAddress: Address, address: Address, storage: ITokenBalanceStorage, dataProvider: IDataProvider) {
        self.contractAddress = contractAddress
        self.address = address
        self.storage = storage
        self.dataProvider = dataProvider
    }

}

extension BalanceManager: IBalanceManager {

    var balance: BigUInt? {
        storage.balance
    }

    func sync() {
        dataProvider.getBalance(contractAddress: contractAddress, address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] balance in
                    self?.storage.balance = balance
                    self?.delegate?.onSyncBalanceSuccess(balance: balance)
                }, onError: { error in
                    self.delegate?.onSyncBalanceFailed(error: error)
                })
                .disposed(by: disposeBag)
    }

}

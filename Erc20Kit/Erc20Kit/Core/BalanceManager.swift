import RxSwift
import BigInt

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let disposeBag = DisposeBag()

    private let contractAddress: Data
    private let address: Data
    private var storage: ITokenBalanceStorage
    private let dataProvider: IDataProvider

    init(contractAddress: Data, address: Data, storage: ITokenBalanceStorage, dataProvider: IDataProvider) {
        self.contractAddress = contractAddress
        self.address = address
        self.storage = storage
        self.dataProvider = dataProvider
    }

}

extension BalanceManager: IBalanceManager {

    var balance: BigUInt? {
        return storage.balance
    }

    func sync() {
        dataProvider.getBalance(contractAddress: contractAddress, address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] balance in
                    self?.storage.balance = balance
                    self?.delegate?.onSyncBalanceSuccess(balance: balance)
                }, onError: { error in
                    self.delegate?.onSyncBalanceError()
                })
                .disposed(by: disposeBag)
    }

    func clear() {
        storage.balance = nil
    }

}

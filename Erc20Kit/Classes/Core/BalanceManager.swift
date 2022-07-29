import EthereumKit
import RxSwift
import BigInt

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let disposeBag = DisposeBag()

    private let storage: Eip20Storage
    private let contractAddress: Address
    private let address: Address
    private let dataProvider: IDataProvider

    init(storage: Eip20Storage, contractAddress: Address, address: Address, dataProvider: IDataProvider) {
        self.storage = storage
        self.contractAddress = contractAddress
        self.address = address
        self.dataProvider = dataProvider
    }

    private func save(balance: BigUInt) {
        storage.save(balance: balance, contractAddress: contractAddress)
    }

}

extension BalanceManager: IBalanceManager {

    var balance: BigUInt? {
        storage.balance(contractAddress: contractAddress)
    }

    func sync() {
        dataProvider.getBalance(contractAddress: contractAddress, address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] balance in
                    self?.save(balance: balance)
                    self?.delegate?.onSyncBalanceSuccess(balance: balance)
                }, onError: { error in
                    self.delegate?.onSyncBalanceFailed(error: error)
                })
                .disposed(by: disposeBag)
    }

}

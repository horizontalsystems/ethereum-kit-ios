import RxSwift

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let disposeBag = DisposeBag()

    private let address: Data
    private let storage: ITokenBalanceStorage
    private let dataProvider: IDataProvider

    init(address: Data, storage: ITokenBalanceStorage, dataProvider: IDataProvider) {
        self.address = address
        self.storage = storage
        self.dataProvider = dataProvider
    }

}

extension BalanceManager: IBalanceManager {

    func balance(contractAddress: Data) -> TokenBalance {
        return storage.tokenBalance(contractAddress: contractAddress) ?? TokenBalance(contractAddress: contractAddress)
    }

    func sync(blockHeight: Int, contractAddress: Data, balancePosition: Int) {
        dataProvider.getStorageValue(contractAddress: contractAddress, position: balancePosition, address: address, blockHeight: blockHeight)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] value in
                    let balance = TokenBalance(contractAddress: contractAddress, value: value, blockHeight: blockHeight)

                    self?.storage.save(tokenBalance: balance)

                    self?.delegate?.onUpdate(balance: balance, contractAddress: contractAddress)
                    self?.delegate?.onSyncBalanceSuccess(contractAddress: contractAddress)
                }, onError: { error in
                    self.delegate?.onSyncBalanceError(contractAddress: contractAddress)
                })
                .disposed(by: disposeBag)
    }

    func clear() {
        storage.clearTokenBalances()
    }

}

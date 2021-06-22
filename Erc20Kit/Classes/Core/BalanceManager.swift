import EthereumKit
import RxSwift
import BigInt

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let disposeBag = DisposeBag()

    private let ethereumKit: EthereumKit.Kit
    private let contractAddress: Address
    private let address: Address
    private let dataProvider: IDataProvider

    init(ethereumKit: EthereumKit.Kit, contractAddress: Address, address: Address, dataProvider: IDataProvider) {
        self.ethereumKit = ethereumKit
        self.contractAddress = contractAddress
        self.address = address
        self.dataProvider = dataProvider
    }

    private func save(balance: BigUInt) {
        ethereumKit.save(balance: balance, contractAddress: contractAddress)
    }

}

extension BalanceManager: IBalanceManager {

    var balance: BigUInt? {
        ethereumKit.balance(contractAddress: contractAddress)
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

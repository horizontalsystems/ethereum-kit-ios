import Foundation
import RxSwift

class GethProvider {
    let geth: Geth

    init(geth: Geth) {
        self.geth = geth
    }

}

extension GethProvider: IGethProviderProtocol {

    func getGasPrice() -> Single<Wei> {
        return Single.create { [weak geth] observer in
            geth?.getGasPrice() { result in
                switch result {
                case .success(let gasPrice):
                    observer(.success(gasPrice))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func getBalance(address: String, blockParameter: BlockParameter) -> Single<Balance> {
        return Single.create { [weak geth] observer in
            geth?.getBalance(of: address, blockParameter: blockParameter) { result in
                switch result {
                case .success(let balance):
                    observer(.success(balance))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func getBlockNumber() -> Single<Int> {
        return Single.create { [weak geth] observer in
            geth?.getBlockNumber() { result in
                switch result {
                case .success(let number):
                    observer(.success(number))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func getTransactionCount(address: String, blockParameter: BlockParameter) -> Single<Int> {
        return Single.create { [weak geth] observer in
            geth?.getTransactionCount(of: address, blockParameter: blockParameter) { result in
                switch result {
                case .success(let count):
                    observer(.success(count))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func sendRawTransaction(rawTransaction: String) -> Single<SentTransaction> {
        return Single.create { [weak geth] observer in
            geth?.sendRawTransaction(rawTransaction: rawTransaction) { result in
                switch result {
                case .success(let sentTransaction):
                    observer(.success(sentTransaction))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func getTransactions(address: String, startBlock: Int64) -> Single<Transactions> {
        return Single.create { [weak geth] observer in
            geth?.getTransactions(address: address, startBlock: startBlock) { result in
                switch result {
                case .success(let transactions):
                    observer(.success(transactions))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

}

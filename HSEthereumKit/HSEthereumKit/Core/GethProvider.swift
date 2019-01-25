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

    func getGasLimit(address: String, data: Data?) -> Single<Wei> {
            return Single.create { [weak geth] observer in

                geth?.getEstimateGas(to: address, data: data?.toHexString().addHexPrefix()) { result in
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

    func getBalance(address: String, contractAddress: String? = nil, blockParameter: BlockParameter) -> Single<Balance> {
        return Single.create { [weak geth] observer in
            let block: (Result<Balance>) -> Void = { result in
                switch result {
                case .success(let balance):
                    observer(.success(balance))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            if let contractAddress = contractAddress {
                geth?.getTokenBalance(contractAddress: contractAddress, address: address, completionHandler: block)
            } else {
                geth?.getBalance(of: address, blockParameter: blockParameter, completionHandler: block)
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

    func getTransactions(address: String, contractAddress: String? = nil, startBlock: Int64) -> Single<Transactions> {
        return Single.create { [weak geth] observer in
            let block: ((Result<Transactions>) -> ()) = { result in
                switch result {
                case .success(let transactions):
                    observer(.success(transactions))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            if let contractAddress = contractAddress {
                geth?.getTokenTransactions(address: address, contractAddress: contractAddress, completionHandler: block)
            } else {
                geth?.getTransactions(address: address, startBlock: startBlock, completionHandler: block)
            }
            return Disposables.create()
        }
    }

}

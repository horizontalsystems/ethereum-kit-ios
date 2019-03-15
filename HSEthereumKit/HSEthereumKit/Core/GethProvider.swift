import Foundation
import RxSwift

class GethProvider {
    private let geth: Geth
    private let hdWallet: Wallet

    init(geth: Geth, hdWallet: Wallet) {
        self.geth = geth
        self.hdWallet = hdWallet
    }

    private func ethereumTransaction(from gethTransaction: Transaction) -> EthereumTransaction {
        let transaction = EthereumTransaction(
                hash: gethTransaction.hash,
                nonce: Int(gethTransaction.nonce) ?? 0,
                input: gethTransaction.input,
                from: EIP55.format(gethTransaction.from),
                to: EIP55.format(gethTransaction.to),
                amount: gethTransaction.value,
                gasLimit: Int(gethTransaction.gas) ?? 0,
                gasPriceInWei: Int(gethTransaction.gasPrice) ?? 0,
                timestamp: TimeInterval(gethTransaction.timeStamp)
        )

        if !gethTransaction.contractAddress.isEmpty {
            transaction.contractAddress = EIP55.format(gethTransaction.contractAddress)
        }

        transaction.blockHash = gethTransaction.blockHash
        transaction.blockNumber = Int(gethTransaction.blockNumber) ?? 0
        transaction.confirmations = Int(gethTransaction.confirmations) ?? 0
        transaction.gasUsed = Int(gethTransaction.gasUsed) ?? 0
        transaction.cumulativeGasUsed = Int(gethTransaction.cumulativeGasUsed) ?? 0
        transaction.isError = gethTransaction.isError == "1"
        transaction.transactionIndex = Int(gethTransaction.transactionIndex) ?? 0
        transaction.txReceiptStatus = gethTransaction.txReceiptStatus == "1"

        return transaction
    }
}

extension GethProvider: IApiProvider {

    func gasPriceInWeiSingle() -> Single<GasPrice> {
        return Single.create { [unowned geth] observer in
            geth.getGasPrice() { result in
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

    func lastBlockHeightSingle() -> Single<Int> {
        return Single.create { [unowned geth] observer in
            geth.getBlockNumber() { result in
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

    func transactionCountSingle(address: String) -> Single<Int> {
        return Single.create { [unowned geth] observer in
            geth.getTransactionCount(of: address, blockParameter: .pending) { result in
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

    func balanceSingle(address: String) -> Single<String> {
        return Single.create { [unowned geth] observer in
            geth.getBalance(of: address, completionHandler: { result in
                switch result {
                case .success(let balance):
                    observer(.success(balance.wei.asString(withBase: 10)))
                case .failure(let error):
                    observer(.error(error))
                }
            })

            return Disposables.create()
        }
    }

    func balanceErc20Single(address: String, contractAddress: String) -> Single<String> {
        return Single.create { [unowned geth] observer in
            geth.getTokenBalance(contractAddress: contractAddress, address: address, completionHandler: { result in
                switch result {
                case .success(let balance):
                    observer(.success(balance.wei.asString(withBase: 10)))
                case .failure(let error):
                    observer(.error(error))
                }
            })

            return Disposables.create()
        }

    }

    func transactionsSingle(address: String, startBlock: Int64) -> Single<[EthereumTransaction]> {
        return Single.create { [unowned self] observer in
            self.geth.getTransactions(address: address, startBlock: startBlock, completionHandler: { result in
                switch result {
                case .success(let transactions):
                    let ethereumTransactions = transactions.elements.map { self.ethereumTransaction(from: $0) }
                    observer(.success(ethereumTransactions))
                case .failure(let error):
                    observer(.error(error))
                }
            })

            return Disposables.create()
        }
    }

    func transactionsErc20Single(address: String, startBlock: Int64) -> Single<[EthereumTransaction]> {
        return Single.create { [unowned self] observer in
            self.geth.getTokenTransactions(address: address, startBlock: startBlock, completionHandler: { result in
                switch result {
                case .success(let transactions):
                    let ethereumTransactions = transactions.elements.map { self.ethereumTransaction(from: $0) }
                    observer(.success(ethereumTransactions))
                case .failure(let error):
                    observer(.error(error))
                }
            })

            return Disposables.create()
        }
    }

    func sendSingle(from: String, to: String, nonce: Int, amount: String, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        return Single.create { [unowned self] observer in
            do {
                let rawTransaction = RawTransaction(wei: amount, to: to, gasPrice: gasPriceInWei, gasLimit: gasLimit, nonce: nonce)

                let signedTransaction = try self.hdWallet.sign(rawTransaction: rawTransaction)

                self.geth.sendRawTransaction(rawTransaction: signedTransaction) { result in
                    switch result {
                    case .success(let sentTransaction):
                        let transaction = EthereumTransaction(
                                hash: sentTransaction.id,
                                nonce: nonce,
                                from: from,
                                to: to,
                                amount: amount,
                                gasLimit: gasLimit,
                                gasPriceInWei: gasPriceInWei
                        )
                        observer(.success(transaction))
                    case .failure(let error):
                        observer(.error(error))
                    }
                }
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    func sendErc20Single(contractAddress: String, from: String, to: String, nonce: Int, amount: String, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        return Single.create { [unowned self] observer in
            do {
                // check value
                guard let bIntValue = BInt(number: amount, withBase: 10) else {
                    throw EthereumKitError.convertError(.failedToConvert(amount))
                }

                // check right contract parameters create
                let params = ERC20.ContractFunctions.transfer(address: to, amount: bIntValue).data
                let rawTransaction = RawTransaction(wei: "0", to: contractAddress, gasPrice: gasPriceInWei, gasLimit: gasLimit, nonce: nonce, data: params)

                let signedTransaction = try self.hdWallet.sign(rawTransaction: rawTransaction)

                self.geth.sendRawTransaction(rawTransaction: signedTransaction) { result in
                    switch result {
                    case .success(let sentTransaction):
                        let transaction = EthereumTransaction(
                                hash: sentTransaction.id,
                                nonce: nonce,
                                input: params.toHexString().addHexPrefix(),
                                from: from,
                                to: to,
                                amount: amount,
                                gasLimit: gasLimit,
                                gasPriceInWei: gasPriceInWei,
                                contractAddress: contractAddress
                        )
                        observer(.success(transaction))
                    case .failure(let error):
                        observer(.error(error))
                    }
                }
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

}

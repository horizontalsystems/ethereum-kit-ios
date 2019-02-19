import Foundation
import RxSwift

class GethProvider {
    private let geth: Geth
    private let hdWallet: Wallet

    init(geth: Geth, hdWallet: Wallet) {
        self.geth = geth
        self.hdWallet = hdWallet
    }

    private func ethereumTransaction(from gethTransaction: Transaction, rate: Decimal) -> EthereumTransaction {
        let transaction = EthereumTransaction(
                hash: gethTransaction.hash,
                nonce: Int(gethTransaction.nonce) ?? 0,
                input: gethTransaction.input,
                from: EIP55.format(gethTransaction.from),
                to: EIP55.format(gethTransaction.to),
                amount: Decimal(string: gethTransaction.value).map { $0 / rate } ?? 0,
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

    func getGasPriceInWei() -> Single<Int> {
        return Single.create { [weak geth] observer in
            geth?.getGasPrice() { result in
                switch result {
                case .success(let gasPriceWei):
                    guard let gasPriceInWei = gasPriceWei.toInt() else {
                        return
                    }

                    observer(.success(gasPriceInWei))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func getLastBlockHeight() -> Single<Int> {
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

    func getTransactionCount(address: String) -> Single<Int> {
        return Single.create { [weak geth] observer in
            geth?.getTransactionCount(of: address, blockParameter: .pending) { result in
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

    func getBalance(address: String) -> Single<Decimal> {
        return Single.create { [weak geth] observer in
            geth?.getBalance(of: address, completionHandler: { result in
                switch result {
                case .success(let balance):
                    do {
                        observer(.success(try balance.ether()))
                    } catch {
                        observer(.error(error))
                    }
                case .failure(let error):
                    observer(.error(error))
                }
            })
            return Disposables.create()
        }
    }

    func getBalanceErc20(address: String, contractAddress: String, decimal: Int) -> Single<Decimal> {
        return Single.create { [weak geth] observer in
            geth?.getTokenBalance(contractAddress: contractAddress, address: address, completionHandler: { result in
                switch result {
                case .success(let balance):
                    let wei = balance.wei

                    guard let decimalWei = Decimal(string: balance.wei.description) else {
                        observer(.error(EthereumKitError.convertError(.failedToConvert(wei.description))))
                        return
                    }
                    observer(.success(decimalWei / pow(Decimal(10), decimal)))
                case .failure(let error):
                    observer(.error(error))
                }
            })
            return Disposables.create()
        }

    }

    func getTransactions(address: String, startBlock: Int64) -> Single<[EthereumTransaction]> {
        return Single.create { [weak self] observer in
            self?.geth.getTransactions(address: address, startBlock: startBlock, completionHandler: { result in
                switch result {
                case .success(let transactions):
                    let ethereumTransactions = transactions.elements.compactMap {
                        self?.ethereumTransaction(from: $0, rate: pow(10, 18))
                    }
                    observer(.success(ethereumTransactions))
                case .failure(let error):
                    observer(.error(error))
                }
            })
            return Disposables.create()
        }
    }

    func getTransactionsErc20(address: String, startBlock: Int64, contracts: [ApiBlockchain.Erc20Contract]) -> Single<[EthereumTransaction]> {
        return Single.create { [weak self] observer in
            self?.geth.getTokenTransactions(address: address, startBlock: startBlock, completionHandler: { result in
                switch result {
                case .success(let transactions):
                    let ethereumTransactions = transactions.elements.compactMap { transaction -> EthereumTransaction? in
                        guard let contract = contracts.first(where: { $0.address == transaction.contractAddress }) else {
                            return nil
                        }
                        return self?.ethereumTransaction(from: transaction, rate: pow(10, contract.decimal))
                    }
                    observer(.success(ethereumTransactions))
                case .failure(let error):
                    observer(.error(error))
                }
            })
            return Disposables.create()
        }
    }

    func send(from: String, to: String, nonce: Int, amount: Decimal, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        return Single.create { [weak self] observer in
            do {
                let weiString = try Converter.toWei(ether: amount).asString(withBase: 10)
                let rawTransaction = RawTransaction(wei: weiString, to: to, gasPrice: gasPriceInWei, gasLimit: gasLimit, nonce: nonce)

                guard let hdWallet = self?.hdWallet else {
                    throw GethError.noHdWallet
                }

                let signedTransaction = try hdWallet.sign(rawTransaction: rawTransaction)

                self?.geth.sendRawTransaction(rawTransaction: signedTransaction) { result in
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

    func sendErc20(contractAddress: String, decimal: Int, from: String, to: String, nonce: Int, amount: Decimal, gasPriceInWei: Int, gasLimit: Int) -> Single<EthereumTransaction> {
        return Single.create { [weak self] observer in
            let contract = ERC20(contractAddress: contractAddress, decimal: decimal)

            do {
                // check value
                let bIntValue = try contract.power(amount: String(describing: amount))

                // check right contract parameters create
                let params = ERC20.ContractFunctions.transfer(address: to, amount: bIntValue).data
                let rawTransaction = RawTransaction(wei: "0", to: contractAddress, gasPrice: gasPriceInWei, gasLimit: gasLimit, nonce: nonce, data: params)

                guard let hdWallet = self?.hdWallet else {
                    throw GethError.noHdWallet
                }

                let signedTransaction = try hdWallet.sign(rawTransaction: rawTransaction)

                self?.geth.sendRawTransaction(rawTransaction: signedTransaction) { result in
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

extension GethProvider {

    enum GethError: Error {
        case noHdWallet
    }

}

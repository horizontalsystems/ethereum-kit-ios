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
                value: Decimal(string: gethTransaction.value).map { $0 / rate } ?? 0,
                gasLimit: Int(gethTransaction.gas) ?? 0,
                gasPrice: Decimal(string: gethTransaction.gasPrice).map { $0 / rate } ?? 0,
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

    func getGasPrice() -> Single<Decimal> {
        return Single.create { [weak geth] observer in
            geth?.getGasPrice() { result in
                switch result {
                case .success(let gasPriceWei):
                    do {
                        let gasPrice = try Converter.toEther(wei: gasPriceWei)
                        observer(.success(gasPrice))
                    } catch {
                        observer(.error(error))
                    }
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
            geth?.getTransactionCount(of: address) { result in
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

    func send(from: String, to: String, nonce: Int, amount: Decimal, gasPrice: Decimal, gasLimit: Int) -> Single<EthereumTransaction> {
        fatalError("send(from:to:nonce:amount:gasPrice:gasLimit:) has not been implemented")
    }

    func sendErc20(contractAddress: String, decimal: Int, from: String, to: String, nonce: Int, amount: Decimal, gasPrice: Decimal, gasLimit: Int) -> Single<EthereumTransaction> {
        fatalError("sendErc20(contractAddress:decimal:from:to:nonce:amount:gasPrice:gasLimit:) has not been implemented")
    }

}

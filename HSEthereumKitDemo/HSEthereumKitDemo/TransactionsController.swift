import UIKit
import RealmSwift
import RxSwift
import HSEthereumKit

class TransactionsController: UITableViewController {
    let disposeBag = DisposeBag()

    var transactions = [EthereumTransaction]()
    var showEthereumTransaction: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Transactions"

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Show Coin", style: .plain, target: self, action: #selector(changeSource))

        tableView.register(UINib(nibName: String(describing: TransactionCell.self), bundle: Bundle(for: TransactionCell.self)), forCellReuseIdentifier: String(describing: TransactionCell.self))

        update()

        Manager.shared.lastBlockHeight.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.update()
        }).disposed(by: disposeBag)

        Manager.shared.transactionsSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            if self?.showEthereumTransaction ?? false {
                self?.update()
            }
        }).disposed(by: disposeBag)

        Manager.shared.erc20Adapter.transactionsSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            if !(self?.showEthereumTransaction ?? true) {
                self?.update()
            }
        }).disposed(by: disposeBag)

    }

    @objc func changeSource() {
        showEthereumTransaction.toggle()
        navigationItem.rightBarButtonItem?.title = showEthereumTransaction ? "Show Coin" : "Show Eth"
        update()
    }

    private func update() {
        guard let ethereumKit = Manager.shared.ethereumKit else {
            return
        }
        let observable = showEthereumTransaction ? ethereumKit.transactions() : ethereumKit.erc20Transactions(contractAddress: Manager.contractAddress)
        observable.subscribe(onSuccess: { [weak self] transactions in
            self?.transactions = transactions
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: TransactionCell.self), for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(transaction: transactions[indexPath.row], index: transactions.count - indexPath.row, lastBlockHeight: Manager.shared.ethereumKit.lastBlockHeight ?? 0)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < transactions.count else {
            return
        }
        print("hash: \(transactions[indexPath.row].txHash)")
    }

}

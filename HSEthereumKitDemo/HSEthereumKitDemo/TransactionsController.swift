import UIKit
import RealmSwift
import RxSwift
import HSEthereumKit

class TransactionsController: UITableViewController {
    let disposeBag = DisposeBag()

    var transactions = [EthereumTransaction]()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Transactions"

        tableView.register(UINib(nibName: String(describing: TransactionCell.self), bundle: Bundle(for: TransactionCell.self)), forCellReuseIdentifier: String(describing: TransactionCell.self))

        update()

        Manager.shared.transactionsSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.update()
        }).disposed(by: disposeBag)

    }

    private func update() {
        Manager.shared.ethereumKit.transactions().subscribe(onSuccess: { transactions in
            self.transactions = transactions
            self.tableView.reloadData()
        })
//TODO
//        transactions = Manager.shared.ethereumKit.erc20Transactions(contractAddress: "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367")
//        tableView.reloadData()
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
            cell.bind(transaction: transactions[indexPath.row], lastBlockHeight: 0)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard indexPath.row < transactions.count else {
//            return
//        }
//        print("hash: \(transactions[indexPath.row].transactionHash)")
    }

}

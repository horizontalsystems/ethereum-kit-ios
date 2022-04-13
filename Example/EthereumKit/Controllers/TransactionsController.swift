import UIKit
import RxSwift

class TransactionsController: UITableViewController {
    private let disposeBag = DisposeBag()

    private var adapters = [IAdapter]()
    private var transactions = [TransactionRecord]()

    private let segmentedControl = UISegmentedControl()

    private let limit = 20
    private var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: String(describing: TransactionCell.self), bundle: Bundle(for: TransactionCell.self)), forCellReuseIdentifier: String(describing: TransactionCell.self))
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero

        adapters.append(Manager.shared.ethereumAdapter)
        adapters.append(contentsOf: Manager.shared.erc20Adapters)

        for (index, adapter) in adapters.enumerated() {
            segmentedControl.insertSegment(withTitle: adapter.coin, at: index, animated: false)

            adapter.lastBlockHeightObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onLastBlockHeightUpdated(index: index)
                    })
                    .disposed(by: disposeBag)

            adapter.transactionsObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onTransactionsUpdated(index: index)
                    })
                    .disposed(by: disposeBag)
        }

        segmentedControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)

        navigationItem.titleView = segmentedControl

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: .valueChanged)
    }

    @objc func onSegmentChanged() {
        transactions = []
        loading = false
        loadNext()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        250
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: TransactionCell.self), for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(transaction: transactions[indexPath.row], coin: currentAdapter.coin, lastBlockHeight: currentAdapter.lastBlockHeight)
        }

        if indexPath.row > transactions.count - 3 {
            loadNext()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = transactions[indexPath.row]

        UIPasteboard.general.setValue(transaction.transactionHash, forPasteboardType: "public.plain-text")

        let alert = UIAlertController(title: "Success", message: "Transaction Hash copied", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)

//        currentAdapter.transactionSingle(hash: transaction.transactionHashData)
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
//                .subscribe(
//                        onSuccess: { fullTransaction in
//                            print("SUCCESS: \(fullTransaction.transaction.hash.toHexString())")
//                        },
//                        onError: { error in
//                            print("ERROR: \(error)")
//                        }
//                )
//                .disposed(by: disposeBag)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    private var currentAdapter: IAdapter {
        adapters[segmentedControl.selectedSegmentIndex]
    }

    private func loadNext() {
        guard !loading else {
            return
        }

        loading = true

        currentAdapter.transactionsSingle(from: transactions.last?.transactionHashData, limit: limit)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.onLoad(transactions: transactions)
                })
                .disposed(by: disposeBag)
    }

    private func onLoad(transactions: [TransactionRecord]) {
        self.transactions.append(contentsOf: transactions)

        tableView.reloadData()

        if transactions.count == limit {
            loading = false
        }
    }

    private func onLastBlockHeightUpdated(index: Int) {
        if index == segmentedControl.selectedSegmentIndex {
            tableView.reloadData()
        }
    }

    private func onTransactionsUpdated(index: Int) {
        if index == segmentedControl.selectedSegmentIndex {
            onSegmentChanged()
        }
    }

}

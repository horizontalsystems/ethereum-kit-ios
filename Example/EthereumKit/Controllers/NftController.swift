import UIKit
import RxSwift
import EthereumKit
import NftKit

class NftController: UITableViewController {
    private let disposeBag = DisposeBag()

    private var nftBalances = [NftBalance]()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "NFT"

        tableView.registerCell(forClass: NftCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero

        Manager.shared.nftKit.nftBalancesObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] nftBalances in
                    self?.nftBalances = nftBalances
                    self?.tableView.reloadData()
                })
                .disposed(by: disposeBag)

        nftBalances = Manager.shared.nftKit.nftBalances
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nftBalances.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: NftCell.self), for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? NftCell {
            cell.bind(nftBalance: nftBalances[indexPath.row])
        }
    }

}

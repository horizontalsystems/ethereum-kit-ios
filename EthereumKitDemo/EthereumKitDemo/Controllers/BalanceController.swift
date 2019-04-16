import UIKit
import RxSwift
import EthereumKit

class BalanceController: UIViewController {
    let disposeBag = DisposeBag()

    @IBOutlet weak var balanceLabel: UILabel?
    @IBOutlet weak var progressLabel: UILabel?
    @IBOutlet weak var lastBlockLabel: UILabel?

    @IBOutlet weak var balanceCoinLabel: UILabel?
    @IBOutlet weak var progressCoinLabel: UILabel?
    
    private lazy var dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d, yyyy, HH:mm"
        return formatter
    }()

    private let ethereumAdapter: BaseAdapter = Manager.shared.ethereumAdapter!
    private let erc20Adapter: BaseAdapter = Manager.shared.erc20Adapter!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Balance"

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        updateLastBlockHeight()

        updateBalance()
        updateState()

        erc20updateBalance()
        erc20updateState()

        ethereumAdapter.lastBlockHeightSignal.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.updateLastBlockHeight()
        }).disposed(by: disposeBag)

        ethereumAdapter.balanceSignal.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.updateBalance()
        }).disposed(by: disposeBag)
        ethereumAdapter.syncStateSignal.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.updateState()
        }).disposed(by: disposeBag)

        erc20Adapter.balanceSignal.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.erc20updateBalance()
        }).disposed(by: disposeBag)

        erc20Adapter.syncStateSignal.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.erc20updateState()
        }).disposed(by: disposeBag)
    }

    @objc func logout() {
        Manager.shared.logout()

        if let window = UIApplication.shared.keyWindow {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = UINavigationController(rootViewController: WordsController())
            })
        }
    }

    @objc func refresh() {
        Manager.shared.ethereumKit.start()
    }

    @IBAction func showDebugInfo() {
        print(Manager.shared.ethereumKit.debugInfo)
    }

    private func updateBalance() {
        balanceLabel?.text = "Balance: \(ethereumAdapter.balance)"
    }

    private func erc20updateBalance() {
        balanceCoinLabel?.text = "Balance Coin: \(erc20Adapter.balance)"
    }

    private func updateState() {
        let kitStateString: String

        switch ethereumAdapter.syncState {
        case .synced: kitStateString = "Synced!"
        case .syncing: kitStateString = "Syncing"
        case .notSynced: kitStateString = "Not Synced"
        }

        progressLabel?.text = "Sync State: \(kitStateString)"
    }

    private func erc20updateState() {
        let kitStateString: String

        switch erc20Adapter.syncState {
        case .synced: kitStateString = "Synced!"
        case .syncing: kitStateString = "Syncing"
        case .notSynced: kitStateString = "Not Synced"
        }

        progressCoinLabel?.text = "Sync State: \(kitStateString)"
    }

    private func updateLastBlockHeight() {
        if let lastBlockHeight = ethereumAdapter.lastBlockHeight {
            lastBlockLabel?.text = "Last Block: \(lastBlockHeight)"
        } else {
            lastBlockLabel?.text = "Last Block: n/a"
        }
    }

}

import UIKit
import RxSwift
import HSEthereumKit

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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Balance"

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        let ethereumKit = Manager.shared.ethereumKit!

        updateLastBlockHeight()

        updateBalance()
        updateState()

        erc20updateBalance()
        erc20updateState()

        Manager.shared.balanceSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.updateBalance()
        }).disposed(by: disposeBag)

        Manager.shared.lastBlockHeight.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.updateLastBlockHeight()
        }).disposed(by: disposeBag)

        Manager.shared.syncStateSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.updateState()
        }).disposed(by: disposeBag)

        Manager.shared.erc20Adapter.balanceSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.erc20updateBalance()
        }).disposed(by: disposeBag)

        Manager.shared.erc20Adapter.syncStateSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.erc20updateState()
        }).disposed(by: disposeBag)

        ethereumKit.start()
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
        balanceLabel?.text = "Balance: \(Manager.shared.ethereumKit.balance)"
    }

    private func erc20updateBalance() {
        balanceCoinLabel?.text = "Balance Coin: \(Manager.shared.ethereumKit.erc20Balance(contractAddress: Manager.contractAddress))"
    }

    private func updateState() {
        let kitStateString: String

        switch Manager.shared.ethereumKit.syncState {
        case .synced: kitStateString = "Synced!"
        case .syncing: kitStateString = "Syncing"
        case .notSynced: kitStateString = "Not Synced"
        }

        progressLabel?.text = "Sync State: \(kitStateString)"
    }

    private func erc20updateState() {
        let kitStateString: String

        switch Manager.shared.ethereumKit.erc20SyncState(contractAddress: Manager.contractAddress) {
        case .synced: kitStateString = "Synced!"
        case .syncing: kitStateString = "Syncing"
        case .notSynced: kitStateString = "Not Synced"
        }

        progressCoinLabel?.text = "Sync State: \(kitStateString)"
    }

    private func updateLastBlockHeight() {
        if let lastBlockHeight = Manager.shared.ethereumKit.lastBlockHeight {
            lastBlockLabel?.text = "Last Block: \(Int(lastBlockHeight))"
        } else {
            lastBlockLabel?.text = "Last Block: n/a"
        }
    }

}

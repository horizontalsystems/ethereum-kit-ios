import UIKit
import RealmSwift
import RxSwift
import HSEthereumKit

class BalanceController: UIViewController {
    let disposeBag = DisposeBag()

    @IBOutlet weak var balanceLabel: UILabel?
    @IBOutlet weak var progressLabel: UILabel?
    @IBOutlet weak var lastBlockLabel: UILabel?

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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(start))

        let walletKit = Manager.shared.walletKit!

        update(balance: walletKit.balance)
        update(progress: walletKit.progress)

        Manager.shared.balanceSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] balance in
            self?.update(balance: balance)
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

    @objc func start() {
        Manager.shared.walletKit.start()
    }

    @IBAction func showRealmInfo() {
        Manager.shared.walletKit.showRealmInfo()
    }

    private func update(balance: BInt) {
        let eth = (try? Converter.toEther(wei: balance)) ?? 0
        balanceLabel?.text = "Balance: \(eth)"
    }

    private func update(progress: Double) {
        progressLabel?.text = "Sync Progress: \(Int(progress * 100))%"
    }

}

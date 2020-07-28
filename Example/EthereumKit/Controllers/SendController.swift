import UIKit
import EthereumKit
import RxSwift

class SendController: UIViewController {
    private let gasLimitPrefix = "Gas Limit: "
    private let disposeBag = DisposeBag()

    @IBOutlet weak var addressTextField: UITextField?
    @IBOutlet weak var amountTextField: UITextField?
    @IBOutlet weak var gasPriceLabel: UILabel?
    @IBOutlet weak var coinLabel: UILabel?
    @IBOutlet weak var sendButton: UIButton?

    private var adapters = [IAdapter]()
    private let segmentedControl = UISegmentedControl()

    private var estimateGasLimit: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        adapters.append(Manager.shared.ethereumAdapter)
        adapters.append(contentsOf: Manager.shared.erc20Adapters)

        for (index, adapter) in adapters.enumerated() {
            segmentedControl.insertSegment(withTitle: adapter.coin, at: index, animated: false)
        }

        segmentedControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)

        navigationItem.titleView = segmentedControl

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: .valueChanged)

        addressTextField?.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        amountTextField?.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc func onSegmentChanged() {
        coinLabel?.text = currentAdapter.coin

        updateEstimatedGasPrice()
    }

    @IBAction func send() {
        guard let addressHex = addressTextField?.text?.trimmingCharacters(in: .whitespaces),
              let estimateGasLimit = estimateGasLimit else {
            return
        }

        guard let address = try? Address(hex: addressHex) else {
            show(error: "Invalid address")
            return
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            show(error: "Invalid amount")
            return
        }

        currentAdapter.sendSingle(to: address, amount: amount, gasLimit: estimateGasLimit)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.addressTextField?.text = ""
                    self?.amountTextField?.text = ""

                    self?.showSuccess(address: address, amount: amount)
                }, onError: { [weak self] error in
                    self?.show(error: "Send failed: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(address: Address, amount: Decimal) {
        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func updateGasLimit(value: Int?) {
        sendButton?.isEnabled = value != nil
        estimateGasLimit = value

        guard let value = value else {
            gasPriceLabel?.text = gasLimitPrefix + " n/a"
            return
        }
        gasPriceLabel?.text = gasLimitPrefix + "\(value)"
    }

    private func updateEstimatedGasPrice() {
        updateGasLimit(value: nil)

        guard let addressHex = addressTextField?.text?.trimmingCharacters(in: .whitespaces),
              let valueText = amountTextField?.text,
              let value = Decimal(string: valueText),
              !value.isZero else {
            return
        }

        guard let address = try? Address(hex: addressHex) else {
            return
        }

        gasPriceLabel?.text = "Loading..."

        currentAdapter.estimatedGasLimit(to: address, value: value)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] gasLimit in
                self?.updateGasLimit(value: gasLimit)
            }, onError: { [weak self] error in
                self?.updateGasLimit(value: nil)
            })
            .disposed(by: disposeBag)
    }

    private var currentAdapter: IAdapter {
        adapters[segmentedControl.selectedSegmentIndex]
    }

    @objc func textFieldDidChange() {
        updateEstimatedGasPrice()
    }

}

import UIKit

class SendController: UIViewController {

    @IBOutlet weak var addressTextField: UITextField?
    @IBOutlet weak var amountTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @IBAction func send() {
        guard let address = addressTextField?.text, !address.isEmpty else {
            show(error: "Empty Address")
            return
        }

        guard let amountString = amountTextField?.text, let amount = Double(amountString) else {
            show(error: "Empty or Non Integer Amount")
            return
        }

        guard let ethereumKit = Manager.shared.ethereumKit else {
            return
        }
        let erc20 = ethereumKit.erc20[0]

        ethereumKit.erc20Send(to: address, contractAddress: erc20.contractAddress, decimal: erc20.decimal, value: Decimal(amount)) { [weak self] error in
            if error != nil {
                self?.show(error: "Something conversion wrong")
            } else {
                self?.showSuccess(address: address, amount: amount)
            }
        }

    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(address: String, amount: Double) {
        addressTextField?.text = ""
        amountTextField?.text = ""

        let alert = UIAlertController(title: "Success", message: "\(amount) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}

import UIKit
import HSEthereumKit

class SendController: UIViewController {

    @IBOutlet weak var addressTextField: UITextField?
    @IBOutlet weak var amountTextField: UITextField?
    @IBOutlet weak var sendCoin: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @IBAction func send(_ sender: Any) {
        guard let address = addressTextField?.text, !address.isEmpty else {
            show(error: "Empty Address")
            return
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            show(error: "Empty or Non Integer Amount")
            return
        }

        guard let ethereumKit = Manager.shared.ethereumKit else {
            return
        }

        let onSuccess: () -> () = { [weak self] in
            self?.showSuccess(address: address, amount: amount)
        }

        let onError: (Error) -> () = { [weak self] error in
            self?.show(error: "Something conversion wrong: \(error)")
        }

        if (sender as? UIButton) == sendCoin {
            ethereumKit.erc20Send(to: address, contractAddress: Manager.contractAddress, amount: amount, onSuccess: onSuccess, onError: onError)
        } else {
            ethereumKit.send(to: address, amount: amount, onSuccess: onSuccess, onError: onError)
        }

    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(address: String, amount: Decimal) {
        addressTextField?.text = ""
        amountTextField?.text = ""

        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}

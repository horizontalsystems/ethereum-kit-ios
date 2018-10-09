import UIKit
import HSEthereumKit

class WordsController: UIViewController {

    @IBOutlet weak var textView: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()
        textView?.text = "mom year father track attend frown loyal goddess crisp abandon juice roof"
        title = "EthereumKit Demo"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @IBAction func generateNewWords() {
        let generatedWords = Mnemonic.create()
        textView?.text = generatedWords.joined(separator: " ")
    }

    @IBAction func login() {
        let words = textView?.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty } ?? []

        do {
            _ = try Mnemonic.createSeed(mnemonic: words)

            Manager.shared.login(words: words)

            if let window = UIApplication.shared.keyWindow {
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = MainController()
                })
            }
        } catch {
            let alert = UIAlertController(title: "Validation Error", message: "\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }

}

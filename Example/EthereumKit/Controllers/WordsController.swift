import UIKit
import EthereumKit
import HdWalletKit
import SnapKit

class WordsController: UIViewController {

    var textView = UITextView()
    var addressFieldView = UITextField()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "EthereumKit Demo"

        let wordsDescriptionLabel = UILabel()
        view.addSubview(wordsDescriptionLabel)
        wordsDescriptionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(100)
        }

        wordsDescriptionLabel.text = "Enter your 12 words separated by space:"

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(wordsDescriptionLabel.snp.bottom).offset(16)
            maker.height.equalTo(85)
        }

        textView.font = UIFont.systemFont(ofSize: 13)
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.layer.cornerRadius = 8
        textView.borderWidth = 1
        textView.borderColor = .gray

        textView.text = Configuration.shared.defaultsWords

        let generateButton = UIButton()
        view.addSubview(generateButton)
        generateButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(textView.snp.bottom).offset(16)
        }

        generateButton.setTitleColor(.blue, for: .normal)
        generateButton.setTitle("Generate New Words", for: .normal)
        generateButton.addTarget(self, action: #selector(generateNewWords), for: .touchUpInside)

        let loginButton = UIButton()
        view.addSubview(loginButton)
        loginButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(generateButton.snp.bottom).offset(16)
        }

        loginButton.setTitleColor(.blue, for: .normal)
        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)

        view.addSubview(addressFieldView)
        addressFieldView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(loginButton.snp.bottom).offset(32)
            maker.height.equalTo(32)
        }

        addressFieldView.placeholder = "Watch Address"
        addressFieldView.cornerRadius = 4
        addressFieldView.borderWidth = 1
        addressFieldView.borderColor = .gray
        addressFieldView.text = "0x2819c144d5946404c0516b6f817a960db37d4929"

        let watchButton = UIButton()
        view.addSubview(watchButton)
        watchButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(addressFieldView.snp.bottom).offset(16)
        }

        watchButton.setTitleColor(.blue, for: .normal)
        watchButton.setTitle("Watch", for: .normal)
        watchButton.addTarget(self, action: #selector(watch), for: .touchUpInside)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc func generateNewWords() {
        if let generatedWords = try? Mnemonic.generate() {
            textView.text = generatedWords.joined(separator: " ")
        }
    }

    @objc func login() {
        let words = textView.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

        do {
            try Mnemonic.validate(words: words)

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

    @IBAction func watch() {
        let text = addressFieldView.text ?? ""

        do {
            let address = try Address(hex: text)

            Manager.shared.watch(address: address)

            if let window = UIApplication.shared.keyWindow {
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = MainController()
                })
            }
        } catch {
            let alert = UIAlertController(title: "Wrong Address", message: "\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }

}

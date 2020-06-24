import UIKit
import EthereumKit
import RxSwift
import SnapKit
import UniswapKit

class SwapController: UIViewController {
    private let disposeBag = DisposeBag()

    private let fromLabel = UILabel()
    private let fromTextField = UITextField()
    private let fromTokenLabel = UILabel()
    private let fromTokenEstimateButton = UIButton(type: .system)
    private let toLabel = UILabel()
    private let toTextField = UITextField()
    private let toTokenLabel = UILabel()
    private let toTokenEstimateButton = UIButton(type: .system)
    private let swapExactFromButton = UIButton(type: .system)
    private let swapExactToButton = UIButton(type: .system)

    private let uniswapKit: UniswapKit.Kit = Manager.shared.uniswapKit

    private let fromToken = Erc20Token(name: "GMO coins", coin: "GMOLW", contractAddress: "0xbb74a24d83470f64d5f0c01688fbb49a5a251b32", decimal: 18)
    private let toToken = Erc20Token(name: "Wrapped ETH", coin: "WETH", contractAddress: "0xc778417e063141139fce010982780140aa0cd5ab", decimal: 18)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Swap"

        view.addSubview(fromLabel)
        fromLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(24)
        }

        fromLabel.text = "From:"

        view.addSubview(fromTextField)
        fromTextField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(24)
            maker.top.equalTo(fromLabel.snp.bottom).offset(8)
            maker.height.equalTo(40)
        }

        fromTextField.layer.cornerRadius = 8
        fromTextField.layer.borderWidth = 1
        fromTextField.layer.borderColor = UIColor.lightGray.cgColor
        fromTextField.delegate = self

        view.addSubview(fromTokenLabel)
        fromTokenLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(fromTextField.snp.trailing).offset(8)
            maker.centerY.equalTo(fromTextField)
            maker.width.equalTo(60)
        }

        fromTokenLabel.font = .systemFont(ofSize: 14)
        fromTokenLabel.text = fromToken.coin

        view.addSubview(fromTokenEstimateButton)
        fromTokenEstimateButton.snp.makeConstraints { maker in
            maker.leading.equalTo(fromTokenLabel.snp.trailing).offset(8)
            maker.trailing.equalToSuperview().inset(24)
            maker.centerY.equalTo(fromTextField)
            maker.width.equalTo(30)
        }

        fromTokenEstimateButton.isEnabled = false
        fromTokenEstimateButton.setTitle("EST", for: .normal)
        fromTokenEstimateButton.addTarget(self, action: #selector(onTapFromTokenEstimate), for: .touchUpInside)

        view.addSubview(toLabel)
        toLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(fromTextField.snp.bottom).offset(16)
        }

        toLabel.text = "To:"

        view.addSubview(toTextField)
        toTextField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(24)
            maker.top.equalTo(toLabel.snp.bottom).offset(8)
            maker.height.equalTo(40)
        }

        toTextField.layer.cornerRadius = 8
        toTextField.layer.borderWidth = 1
        toTextField.layer.borderColor = UIColor.lightGray.cgColor
        toTextField.delegate = self

        view.addSubview(toTokenLabel)
        toTokenLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(toTextField.snp.trailing).offset(8)
            maker.centerY.equalTo(toTextField)
            maker.width.equalTo(60)
        }

        toTokenLabel.font = .systemFont(ofSize: 14)
        toTokenLabel.text = toToken.coin

        view.addSubview(toTokenEstimateButton)
        toTokenEstimateButton.snp.makeConstraints { maker in
            maker.leading.equalTo(toTokenLabel.snp.trailing).offset(8)
            maker.trailing.equalToSuperview().inset(24)
            maker.centerY.equalTo(toTextField)
            maker.width.equalTo(30)
        }

        toTokenEstimateButton.isEnabled = false
        toTokenEstimateButton.setTitle("EST", for: .normal)
        toTokenEstimateButton.addTarget(self, action: #selector(onTapToTokenEstimate), for: .touchUpInside)

        view.addSubview(swapExactFromButton)
        swapExactFromButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(toTextField.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }

        swapExactFromButton.isEnabled = false
        swapExactFromButton.setTitle("SWAP EXACT FROM", for: .normal)
        swapExactFromButton.addTarget(self, action: #selector(onTapSwapExactFrom), for: .touchUpInside)

        view.addSubview(swapExactToButton)
        swapExactToButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(swapExactFromButton.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }

        swapExactToButton.isEnabled = false
        swapExactToButton.setTitle("SWAP EXACT TO", for: .normal)
        swapExactToButton.addTarget(self, action: #selector(onTapSwapExactTo), for: .touchUpInside)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc private func onTapSwapExactFrom() {
        guard let fromAmountString = fromTextField.text, let fromAmountDecimal = Decimal(string: fromAmountString) else {
            return
        }

        guard let toAmountString = toTextField.text, let toAmountDecimal = Decimal(string: toAmountString) else {
            return
        }

        let amountFrom = fromAmountDecimal.roundedString(decimal: 18)
        let amountTo = toAmountDecimal.roundedString(decimal: 18)

        if fromToken.coin == "WETH" {
            swapExactETHForTokens(amount: amountFrom, amountOutMin: amountTo)
        }
    }

    @objc private func onTapSwapExactTo() {
        guard let fromAmountString = fromTextField.text, let fromAmountDecimal = Decimal(string: fromAmountString) else {
            return
        }

        guard let toAmountString = toTextField.text, let toAmountDecimal = Decimal(string: toAmountString) else {
            return
        }

        let amountFrom = fromAmountDecimal.roundedString(decimal: 18)
        let amountTo = toAmountDecimal.roundedString(decimal: 18)

        if toToken.coin == "WETH" {
            swapTokensForExactETH(amount: amountTo, amountInMax: amountFrom)
        }
    }

    @objc private func onTapFromTokenEstimate() {
        guard let fromAmountString = fromTextField.text, let fromAmountDecimal = Decimal(string: fromAmountString) else {
            return
        }

        uniswapKit.amountsOutSingle(
                        amountIn: fromAmountDecimal.roundedString(decimal: fromToken.decimal),
                        fromContractAddress: fromToken.contractAddress,
                        toContractAddress: toToken.contractAddress
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] amountIn, amountOut in
                    self?.handleAmounts(amountIn: amountIn, amountOut: amountOut)
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @objc private func onTapToTokenEstimate() {
        guard let toAmountString = toTextField.text, let toAmountDecimal = Decimal(string: toAmountString) else {
            return
        }

        uniswapKit.amountsInSingle(
                        amountOut: toAmountDecimal.roundedString(decimal: toToken.decimal),
                        fromContractAddress: fromToken.contractAddress,
                        toContractAddress: toToken.contractAddress
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] amountIn, amountOut in
                    self?.handleAmounts(amountIn: amountIn, amountOut: amountOut)
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func handleAmounts(amountIn: String, amountOut: String) {
        if let significand = Decimal(string: amountIn) {
            fromTextField.text = Decimal(sign: .plus, exponent: -fromToken.decimal, significand: significand).description
        }

        if let significand = Decimal(string: amountOut) {
            toTextField.text = Decimal(sign: .plus, exponent: -toToken.decimal, significand: significand).description
        }
    }

    private func swapExactETHForTokens(amount: String, amountOutMin: String) {
        uniswapKit.swapExactETHForTokens(
                        amount: amount,
                        amountOutMin: amountOutMin,
                        toContractAddress: toToken.contractAddress
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { txHash in
                    print("SUCCESS: \(txHash)")
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func swapTokensForExactETH(amount: String, amountInMax: String) {
        uniswapKit.swapTokensForExactETH(
                        amount: amount,
                        amountInMax: amountInMax,
                        fromContractAddress: fromToken.contractAddress
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { txHash in
                    print("SUCCESS: \(txHash)")
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

}

extension SwapController: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == fromTextField {
            toTextField.text = nil
            swapExactFromButton.isEnabled = true
            swapExactToButton.isEnabled = false
            fromTokenEstimateButton.isEnabled = true
            toTokenEstimateButton.isEnabled = false
        }

        if textField == toTextField {
            fromTextField.text = nil
            swapExactToButton.isEnabled = true
            swapExactFromButton.isEnabled = false
            toTokenEstimateButton.isEnabled = true
            fromTokenEstimateButton.isEnabled = false
        }
    }

}

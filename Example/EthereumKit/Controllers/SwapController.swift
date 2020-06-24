import UIKit
import EthereumKit
import RxSwift
import SnapKit
import UniswapKit

class SwapController: UIViewController {
    private let disposeBag = DisposeBag()

    private let fromLabel = UILabel()
    private let fromTextField = UITextField()
    private let fromTokenButton = UIButton(type: .system)
    private let toLabel = UILabel()
    private let toTextField = UITextField()
    private let toTokenButton = UIButton(type: .system)
    private let swapButton = UIButton(type: .system)

    private let uniswapKit: UniswapKit.Kit = Manager.shared.uniswapKit

    private let wethContractAddress = "0xc778417e063141139fce010982780140aa0cd5ab"
    private let gmoContractAddress = "0xbb74a24d83470f64d5f0c01688fbb49a5a251b32"

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

        view.addSubview(fromTokenButton)
        fromTokenButton.snp.makeConstraints { maker in
            maker.leading.equalTo(fromTextField.snp.trailing).offset(8)
            maker.trailing.equalToSuperview().inset(24)
            maker.centerY.equalTo(fromTextField)
            maker.width.equalTo(60)
        }

        fromTokenButton.setTitle("ETH", for: .normal)
        fromTokenButton.addTarget(self, action: #selector(onTapFromToken), for: .touchUpInside)

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

        view.addSubview(toTokenButton)
        toTokenButton.snp.makeConstraints { maker in
            maker.leading.equalTo(toTextField.snp.trailing).offset(8)
            maker.trailing.equalToSuperview().inset(24)
            maker.centerY.equalTo(toTextField)
            maker.width.equalTo(60)
        }

        toTokenButton.setTitle("GMOLW", for: .normal)
        toTokenButton.addTarget(self, action: #selector(onTapToToken), for: .touchUpInside)

        view.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(toTextField.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }

        swapButton.setTitle("SWAP", for: .normal)
        swapButton.addTarget(self, action: #selector(onTapSwap), for: .touchUpInside)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc private func onTapSwap() {
        guard let fromAmountString = fromTextField.text, let fromAmountDecimal = Decimal(string: fromAmountString) else {
            return
        }

        guard let toAmountString = toTextField.text, let toAmountDecimal = Decimal(string: toAmountString) else {
            return
        }

        uniswapKit.swapExactETHForTokens(
                        amount: fromAmountDecimal.roundedString(decimal: 18),
                        amountOutMin: toAmountDecimal.roundedString(decimal: 18),
                        toContractAddress: gmoContractAddress
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] txHash in
                    print("SUCCESS: \(txHash)")
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @objc private func onTapFromToken() {
        guard let fromAmountString = fromTextField.text, let fromAmountDecimal = Decimal(string: fromAmountString) else {
            return
        }

        uniswapKit.amountsOutSingle(
                        amountIn: fromAmountDecimal.roundedString(decimal: 18),
                        fromContractAddress: wethContractAddress,
                        toContractAddress: gmoContractAddress
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

    @objc private func onTapToToken() {
        guard let toAmountString = toTextField.text, let toAmountDecimal = Decimal(string: toAmountString) else {
            return
        }

        uniswapKit.amountsInSingle(
                        amountOut: toAmountDecimal.roundedString(decimal: 18),
                        fromContractAddress: wethContractAddress,
                        toContractAddress: gmoContractAddress
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
            fromTextField.text = Decimal(sign: .plus, exponent: -18, significand: significand).description
        }

        if let significand = Decimal(string: amountOut) {
            toTextField.text = Decimal(sign: .plus, exponent: -18, significand: significand).description
        }
    }

}

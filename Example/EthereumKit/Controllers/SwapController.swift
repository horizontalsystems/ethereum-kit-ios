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
    private let pathLabel = UILabel()
    private let swapButton = UIButton(type: .system)

    private let uniswapKit: UniswapKit.Kit = Manager.shared.uniswapKit

    private var mode: Mode = .exactFrom
    private var pathItems: [PathItem]?

    private static let tokens = [
        Erc20Token(name: "GMO coins", coin: "GMOLW", contractAddress: "0xbb74a24d83470f64d5f0c01688fbb49a5a251b32", decimal: 18),
        Erc20Token(name: "UniGay", coin: "UGAY", contractAddress: "0x13338d72b25bb5a4af2122afb70f1264cffa8bce", decimal: 18),
    ]

    private var fromToken: Erc20Token?
    private var toToken: Erc20Token? = SwapController.tokens[1]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Swap"

        view.addSubview(fromLabel)
        fromLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(24)
        }

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
        fromTokenLabel.text = fromToken?.coin ?? "ETH"

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
        toTokenLabel.text = toToken?.coin ?? "ETH"

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

        view.addSubview(pathLabel)
        pathLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(toTextField.snp.bottom).offset(24)
        }

        pathLabel.font = .systemFont(ofSize: 12)
        pathLabel.textAlignment = .center

        view.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(pathLabel.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }

        swapButton.isEnabled = false
        swapButton.setTitle("SWAP", for: .normal)
        swapButton.addTarget(self, action: #selector(onTapSwap), for: .touchUpInside)

        syncLabels()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    private func syncLabels() {
        fromLabel.text = "From:\(mode == .exactTo ? " (estimated)" : "")"
        toLabel.text = "To:\(mode == .exactFrom ? " (estimated)" : "")"
    }

    @objc private func onTapSwap() {
        guard let pathItems = pathItems else {
            return
        }

        let single: Single<String>

        switch mode {
        case .exactFrom: single = uniswapKit.swapExactItemForItem(pathItems: pathItems)
        case .exactTo: single = uniswapKit.swapItemForExactItem(pathItems: pathItems)
        }

        single
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { txHash in
                    print("SUCCESS: \(txHash)")
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @objc private func onTapFromTokenEstimate() {
        guard let fromAmountString = fromTextField.text, let fromAmountDecimal = Decimal(string: fromAmountString) else {
            return
        }

        uniswapKit.amountsOutSingle(
                        amountIn: fromAmountDecimal.roundedString(decimal: fromToken?.decimal ?? 18),
                        fromItem: fromToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum,
                        toItem: toToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] pathItems in
                    self?.handle(pathItems: pathItems)
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
                        amountOut: toAmountDecimal.roundedString(decimal: toToken?.decimal ?? 18),
                        fromItem: fromToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum,
                        toItem: toToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] pathItems in
                    self?.handle(pathItems: pathItems)
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func handle(pathItems: [PathItem]) {
        self.pathItems = pathItems
        swapButton.isEnabled = true

        if let firstItem = pathItems.first, let significand = Decimal(string: firstItem.amount) {
            fromTextField.text = Decimal(sign: .plus, exponent: -(fromToken?.decimal ?? 18), significand: significand).description
        }

        if let lastItem = pathItems.last, let significand = Decimal(string: lastItem.amount) {
            toTextField.text = Decimal(sign: .plus, exponent: -(toToken?.decimal ?? 18), significand: significand).description
        }

        let paths = pathItems.map { pathItem -> String in
            switch pathItem.swapItem {
            case .ethereum: return "ETH"
            case .erc20(let contractAddress):
                return SwapController.tokens.first(where: { $0.contractAddress == contractAddress })?.coin ?? "???"
            }
        }

        pathLabel.text = paths.joined(separator: "  >  ")
    }

}

extension SwapController: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == fromTextField {
            toTextField.text = nil
            pathLabel.text = nil
            swapButton.isEnabled = false
            fromTokenEstimateButton.isEnabled = true
            toTokenEstimateButton.isEnabled = false

            mode = .exactFrom
            syncLabels()
        }

        if textField == toTextField {
            fromTextField.text = nil
            pathLabel.text = nil
            swapButton.isEnabled = false
            toTokenEstimateButton.isEnabled = true
            fromTokenEstimateButton.isEnabled = false

            mode = .exactTo
            syncLabels()
        }
    }

}

extension SwapController {

    enum Mode {
        case exactFrom
        case exactTo
    }

}

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
    private let toLabel = UILabel()
    private let toTextField = UITextField()
    private let toTokenLabel = UILabel()
    private let pathLabel = UILabel()
    private let swapButton = UIButton(type: .system)

    private let uniswapKit: UniswapKit.Kit = Manager.shared.uniswapKit

    private var pairs: [Pair]?
    private var tradeInfo: TradeInfo?

    private static let tokens = [
        Erc20Token(name: "GMO coins", coin: "GMOLW", contractAddress: "0xbb74a24d83470f64d5f0c01688fbb49a5a251b32", decimal: 18),
        Erc20Token(name: "DAI", coin: "DAI", contractAddress: "0xad6d458402f60fd3bd25163575031acdce07538d", decimal: 18),

//        Erc20Token(name: "DAI", coin: "DAI", contractAddress: "0x6b175474e89094c44da98b954eedeac495271d0f", decimal: 18),
//        Erc20Token(name: "USD Coin", coin: "USDC", contractAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", decimal: 6),
    ]

    private var fromToken: Erc20Token? = SwapController.tokens[1]
    private var toToken: Erc20Token?

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
        fromTextField.addTarget(self, action: #selector(onChangeAmountIn), for: .editingChanged)

        view.addSubview(fromTokenLabel)
        fromTokenLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(fromTextField.snp.trailing).offset(8)
            maker.trailing.equalToSuperview().inset(24)
            maker.centerY.equalTo(fromTextField)
            maker.width.equalTo(60)
        }

        fromTokenLabel.font = .systemFont(ofSize: 14)
        fromTokenLabel.text = fromToken?.coin ?? "ETH"

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
        toTextField.addTarget(self, action: #selector(onChangeAmountOut), for: .editingChanged)

        view.addSubview(toTokenLabel)
        toTokenLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(toTextField.snp.trailing).offset(8)
            maker.trailing.equalToSuperview().inset(24)
            maker.centerY.equalTo(toTextField)
            maker.width.equalTo(60)
        }

        toTokenLabel.font = .systemFont(ofSize: 14)
        toTokenLabel.text = toToken?.coin ?? "ETH"

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

        syncControls()

        syncPairs()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    private func syncControls() {
        let tradeType: TradeType = tradeInfo?.type ?? .exactIn

        fromLabel.text = "From:\(tradeType == .exactIn ? " (estimated)" : "")"
        toLabel.text = "To:\(tradeType == .exactOut ? " (estimated)" : "")"

        swapButton.isEnabled = tradeInfo != nil
    }

    private func syncPairs() {
        uniswapKit.pairsSingle(
                        itemIn: fromToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum,
                        itemOut: toToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] pairs in
                    self?.pairs = pairs

                    for pair in pairs {
                        print(pair)
                    }
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @objc private func onChangeAmountIn() {
        tradeInfo = nil

        guard let fromAmountString = fromTextField.text, let fromAmountDecimal = Decimal(string: fromAmountString) else {
            toTextField.text = nil
            syncControls()
            return
        }

        guard let pairs = pairs else {
            syncControls()
            return
        }

        tradeInfo = uniswapKit.bestTradeExactIn(
                pairs: pairs,
                itemIn: fromToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum,
                itemOut: toToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum,
                amountIn: fromAmountDecimal.roundedString(decimal: fromToken?.decimal ?? 18)
        )

        syncControls()

        if let tradeInfo = tradeInfo, let significand = Decimal(string: tradeInfo.amountOut) {
            toTextField.text = Decimal(sign: .plus, exponent: -(toToken?.decimal ?? 18), significand: significand).description
        }
    }

    @objc private func onChangeAmountOut() {
        tradeInfo = nil

        guard let toAmountString = toTextField.text, let toAmountDecimal = Decimal(string: toAmountString) else {
            fromTextField.text = nil
            syncControls()
            return
        }

        guard let pairs = pairs else {
            syncControls()
            return
        }

        tradeInfo = uniswapKit.bestTradeExactOut(
                pairs: pairs,
                itemIn: fromToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum,
                itemOut: toToken.map { .erc20(contractAddress: $0.contractAddress) } ?? .ethereum,
                amountOut: toAmountDecimal.roundedString(decimal: toToken?.decimal ?? 18)
        )

        syncControls()

        if let tradeInfo = tradeInfo, let significand = Decimal(string: tradeInfo.amountIn) {
            fromTextField.text = Decimal(sign: .plus, exponent: -(fromToken?.decimal ?? 18), significand: significand).description
        }
    }

    @objc private func onTapSwap() {
        guard let tradeInfo = tradeInfo else {
            return
        }

        uniswapKit.swapSingle(tradeInfo: tradeInfo)
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

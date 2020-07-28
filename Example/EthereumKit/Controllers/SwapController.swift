import UIKit
import EthereumKit
import RxSwift
import SnapKit
import UniswapKit
import BigInt

class SwapController: UIViewController {
    private let disposeBag = DisposeBag()

    private let fromLabel = UILabel()
    private let fromTextField = UITextField()
    private let fromTokenLabel = UILabel()
    private let toLabel = UILabel()
    private let toTextField = UITextField()
    private let toTokenLabel = UILabel()
    private let minMaxLabel = UILabel()
    private let executionPriceLabel = UILabel()
    private let midPriceLabel = UILabel()
    private let priceImpactLabel = UILabel()
    private let pathLabel = UILabel()
    private let approveButton = UIButton(type: .system)
    private let swapButton = UIButton(type: .system)

    private let uniswapKit: UniswapKit.Kit = Manager.shared.uniswapKit

    private var swapData: SwapData?
    private var tradeData: TradeData?

    private let gasPrice = 200_000_000_000

    private var fromAdapter: Erc20Adapter? = Manager.shared.erc20Adapters[1]
    private var toAdapter: Erc20Adapter? = Manager.shared.erc20Adapters[0]

    private var fromToken: Erc20Token? { fromAdapter?.token }
    private var toToken: Erc20Token? { toAdapter?.token }

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
        fromTokenLabel.text = tokenCoin(token: fromToken)

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
        toTokenLabel.text = tokenCoin(token: toToken)

        view.addSubview(minMaxLabel)
        minMaxLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(toTextField.snp.bottom).offset(24)
        }

        minMaxLabel.font = .systemFont(ofSize: 12)
        minMaxLabel.textAlignment = .left

        view.addSubview(executionPriceLabel)
        executionPriceLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(minMaxLabel.snp.bottom).offset(12)
        }

        executionPriceLabel.font = .systemFont(ofSize: 12)
        executionPriceLabel.textAlignment = .left

        view.addSubview(midPriceLabel)
        midPriceLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(executionPriceLabel.snp.bottom).offset(12)
        }

        midPriceLabel.font = .systemFont(ofSize: 12)
        midPriceLabel.textAlignment = .left

        view.addSubview(priceImpactLabel)
        priceImpactLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(midPriceLabel.snp.bottom).offset(12)
        }

        priceImpactLabel.font = .systemFont(ofSize: 12)
        priceImpactLabel.textAlignment = .left

        view.addSubview(pathLabel)
        pathLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(priceImpactLabel.snp.bottom).offset(12)
        }

        pathLabel.font = .systemFont(ofSize: 12)
        pathLabel.textAlignment = .left

        view.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(24)
            maker.top.equalTo(pathLabel.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }

        approveButton.isEnabled = false
        approveButton.setTitle("APPROVE", for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        view.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.leading.equalTo(approveButton.snp.trailing).offset(24)
            maker.top.equalTo(approveButton.snp.top)
            maker.trailing.equalToSuperview().inset(24)
            maker.height.equalTo(40)
            maker.width.equalTo(approveButton)
        }

        swapButton.isEnabled = false
        swapButton.setTitle("SWAP", for: .normal)
        swapButton.addTarget(self, action: #selector(onTapSwap), for: .touchUpInside)

        syncControls()

        syncAllowance()
        syncSwapData()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    private func pathString(path: [Token]) -> String {
        let parts = path.map { token -> String in
            if token.isEther {
                return "ETH"
            } else if let erc20Token = Configuration.shared.erc20Tokens.first(where: { $0.contractAddress.eip55.lowercased() == token.address.eip55.lowercased() }) {
                return erc20Token.coin
            } else {
                return token.address.eip55
            }
        }

        return parts.joined(separator: " > ")
    }

    private func syncControls() {
        let tradeType: TradeType = tradeData?.type ?? .exactIn

        fromLabel.text = "From:\(tradeType == .exactOut ? " (estimated)" : "")"
        toLabel.text = "To:\(tradeType == .exactIn ? " (estimated)" : "")"

        approveButton.isEnabled = tradeData != nil
        swapButton.isEnabled = tradeData != nil

        if let tradeData = tradeData {
            switch tradeData.type {
            case .exactIn:
                minMaxLabel.text = tradeData.amountOutMin.map { "Minimum Received: \($0.description) \(tokenCoin(token: toToken))" }
            case .exactOut:
                minMaxLabel.text = tradeData.amountInMax.map { "Maximum Sold: \($0.description) \(tokenCoin(token: fromToken))" }
            }

            executionPriceLabel.text = tradeData.executionPrice.map { "Execution Price: \($0.description) \(tokenCoin(token: toToken)) per \(tokenCoin(token: fromToken))" }
            midPriceLabel.text = tradeData.midPrice.map { "Mid Price: \($0.description) \(tokenCoin(token: toToken)) per \(tokenCoin(token: fromToken))" }

            priceImpactLabel.text = tradeData.priceImpact.map { "Price Impact: \($0.description)%" }

            pathLabel.text = "Route: \(pathString(path: tradeData.path))"
        } else {
            minMaxLabel.text = nil
            executionPriceLabel.text = nil
            midPriceLabel.text = nil
            priceImpactLabel.text = nil
            pathLabel.text = nil
        }
    }

    private func tokenCoin(token: Erc20Token?) -> String {
        token?.coin ?? "ETH"
    }

    private func uniswapToken(token: Erc20Token?) -> Token {
        guard let token = token else {
            return uniswapKit.etherToken
        }

        return uniswapKit.token(contractAddress: token.contractAddress, decimals: token.decimal)
    }

    private func amount(textField: UITextField) -> Decimal? {
        guard let string = textField.text else {
            return nil
        }

        return Decimal(string: string)
    }

    private func syncAllowance() {
        fromAdapter?.allowanceSingle(spenderAddress: uniswapKit.routerAddress)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { allowance in
                    print("Allowance: \(allowance)")
                }, onError: { error in
                    print("ALLOWANCE ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func syncSwapData() {
        fromTextField.isEnabled = false
        toTextField.isEnabled = false

        let tokenIn = uniswapToken(token: fromToken)
        let tokenOut = uniswapToken(token: toToken)

        uniswapKit.swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] swapData in
                    print("SwapData:\n\(swapData)")

                    self?.swapData = swapData

                    self?.fromTextField.isEnabled = true
                    self?.toTextField.isEnabled = true
                }, onError: { error in
                    print("SWAP DATA ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @objc private func onChangeAmountIn() {
        tradeData = nil

        guard let amountIn = amount(textField: fromTextField) else {
            toTextField.text = nil
            syncControls()
            return
        }

        guard let swapData = swapData else {
            syncControls()
            return
        }

        do {
            tradeData = try uniswapKit.bestTradeExactIn(
                    swapData: swapData,
                    amountIn: amountIn
            )
        } catch {
            print("ERROR: \(error)")
        }

        syncControls()

        toTextField.text = tradeData?.amountOut?.description
    }

    @objc private func onChangeAmountOut() {
        tradeData = nil

        guard let amountOut = amount(textField: toTextField) else {
            fromTextField.text = nil
            syncControls()
            return
        }

        guard let swapData = swapData else {
            syncControls()
            return
        }

        do {
            tradeData = try uniswapKit.bestTradeExactOut(
                    swapData: swapData,
                    amountOut: amountOut
            )
        } catch {
            print("ERROR: \(error)")
        }

        syncControls()

        fromTextField.text = tradeData?.amountIn?.description
    }

    @objc private func onTapApprove() {
        guard let adapter = fromAdapter else {
            return
        }

        guard let amount = amount(textField: fromTextField) else {
            return
        }

        let gasPrice = self.gasPrice
        let spenderAddress = uniswapKit.routerAddress

        adapter.estimateApproveSingle(spenderAddress: spenderAddress, amount: amount, gasPrice: gasPrice)
                .flatMap { gasLimit -> Single<String> in
                    print("GAS LIMIT SUCCESS: \(gasLimit)")
                    return adapter.approveSingle(spenderAddress: spenderAddress, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice)
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { txHash in
                    print("SUCCESS: \(txHash)")
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @objc private func onTapSwap() {
        guard let tradeData = tradeData else {
            return
        }

        uniswapKit.estimateSwapSingle(tradeData: tradeData, gasPrice: gasPrice)
                .flatMap { [unowned self] gasLimit -> Single<String> in
                    print("GAS LIMIT SUCCESS: \(gasLimit)")
                    return self.uniswapKit.swapSingle(tradeData: tradeData, gasLimit: gasLimit, gasPrice: self.gasPrice)
                }
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

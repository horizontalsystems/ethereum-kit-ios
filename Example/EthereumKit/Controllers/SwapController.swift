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
    private let fromBalanceLabel = UILabel()
    private let allowanceLabel = UILabel()
    private let toLabel = UILabel()
    private let toTextField = UITextField()
    private let toTokenLabel = UILabel()
    private let toBalanceLabel = UILabel()
    private let minMaxLabel = UILabel()
    private let executionPriceLabel = UILabel()
    private let midPriceLabel = UILabel()
    private let priceImpactLabel = UILabel()
    private let providerFeeLabel = UILabel()
    private let pathLabel = UILabel()
    private let approveButton = UIButton(type: .system)
    private let swapButton = UIButton(type: .system)

    private let uniswapKit: UniswapKit.Kit = Manager.shared.uniswapKit

    private var swapData: SwapData?
    private var tradeData: TradeData?
    private var allowance: Decimal?

    private let gasPrice = 200_000_000_000

    private let ethereumKit = Manager.shared.ethereumKit!
    private let fromAdapter: IAdapter = Manager.shared.erc20Adapters[1]
    private let toAdapter: IAdapter = Manager.shared.ethereumAdapter

    private var fromToken: Erc20Token? { erc20Token(adapter: fromAdapter) }
    private var toToken: Erc20Token? { erc20Token(adapter: toAdapter) }

    private func erc20Token(adapter: IAdapter) -> Erc20Token? {
        guard let erc20Adapter = adapter as? Erc20Adapter else {
            return nil
        }

        return erc20Adapter.token
    }

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

        view.addSubview(fromBalanceLabel)
        fromBalanceLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(fromTextField.snp.bottom).offset(12)
        }

        fromBalanceLabel.font = .systemFont(ofSize: 12)
        fromBalanceLabel.textAlignment = .left
        fromBalanceLabel.text = "Balance: \(fromAdapter.balance) \(tokenCoin(token: fromToken))"

        view.addSubview(allowanceLabel)
        allowanceLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(fromBalanceLabel.snp.bottom).offset(12)
        }

        allowanceLabel.font = .systemFont(ofSize: 12)
        allowanceLabel.textAlignment = .left

        view.addSubview(toLabel)
        toLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(allowanceLabel.snp.bottom).offset(16)
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

        view.addSubview(toBalanceLabel)
        toBalanceLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(toTextField.snp.bottom).offset(12)
        }

        toBalanceLabel.font = .systemFont(ofSize: 12)
        toBalanceLabel.textAlignment = .left
        toBalanceLabel.text = "Balance: \(toAdapter.balance) \(tokenCoin(token: toToken))"

        view.addSubview(minMaxLabel)
        minMaxLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(toBalanceLabel.snp.bottom).offset(24)
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

        view.addSubview(providerFeeLabel)
        providerFeeLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(priceImpactLabel.snp.bottom).offset(12)
        }

        providerFeeLabel.font = .systemFont(ofSize: 12)
        providerFeeLabel.textAlignment = .left

        view.addSubview(pathLabel)
        pathLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(providerFeeLabel.snp.bottom).offset(12)
        }

        pathLabel.font = .systemFont(ofSize: 12)
        pathLabel.textAlignment = .left

        view.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(pathLabel.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }

        approveButton.setTitle("APPROVE", for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        view.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(24)
            maker.top.equalTo(pathLabel.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }

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
            } else if let erc20Token = Configuration.shared.erc20Tokens.first(where: { $0.contractAddress.hex.lowercased() == token.address.hex.lowercased() }) {
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
            providerFeeLabel.text = tradeData.providerFee.map { "Provider Fee: \($0.description)" }

            pathLabel.text = "Route: \(pathString(path: tradeData.path))"
        } else {
            minMaxLabel.text = nil
            executionPriceLabel.text = nil
            midPriceLabel.text = nil
            priceImpactLabel.text = nil
            providerFeeLabel.text = nil
            pathLabel.text = nil
        }

        let amountIn = tradeData?.amountIn ?? 0

        let allowanceRequired: Bool
        if fromAdapter is EthereumAdapter {
            allowanceRequired = false
            allowanceLabel.text = " "
        } else {
            if let allowance = allowance {
                allowanceRequired = amountIn > allowance
                allowanceLabel.text = "Allowance: \(allowance) \(tokenCoin(token: fromToken))"
            } else {
                allowanceRequired = true
                allowanceLabel.text = "Allowance: loading..."
            }
        }

        approveButton.isHidden = tradeData == nil || !allowanceRequired

        let balanceSufficient = amountIn <= fromAdapter.balance

        swapButton.isHidden = tradeData == nil || allowanceRequired || !balanceSufficient
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
        guard let fromAdapter = fromAdapter as? Erc20Adapter else {
            return
        }

        fromAdapter.allowanceSingle(spenderAddress: uniswapKit.routerAddress)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] allowance in
                    self?.onSync(allowance: allowance)
                }, onError: { error in
                    print("ALLOWANCE ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func onSync(allowance: Decimal) {
        self.allowance = allowance
        syncControls()
    }

    private func syncSwapData() {
        let tokenIn = uniswapToken(token: fromToken)
        let tokenOut = uniswapToken(token: toToken)

        uniswapKit.swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] swapData in
//                    print("SwapData:\n\(swapData)")

                    self?.swapData = swapData
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
        guard let adapter = fromAdapter as? Erc20Adapter, let token = fromToken else {
            return
        }

        guard let decimalAmount = amount(textField: fromTextField), let amount = BigUInt(decimalAmount.roundedString(decimal: token.decimal)) else {
            return
        }

        let gasPrice = self.gasPrice
        let spenderAddress = uniswapKit.routerAddress
        
        let transactionData = adapter.erc20Kit.approveTransactionData(spenderAddress: spenderAddress, amount: amount)

        ethereumKit.estimateGas(to: transactionData.to, amount: transactionData.value, gasPrice: gasPrice, data: transactionData.input)
                .flatMap { gasLimit -> Single<TransactionWithInternal> in
                    print("GAS LIMIT SUCCESS: \(gasLimit)")
                    return self.ethereumKit.sendSingle(address: transactionData.to, value: transactionData.value, transactionInput: transactionData.input, gasPrice: gasPrice, gasLimit: gasLimit)
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

        do {
            let transactionData = try uniswapKit.transactionData(tradeData: tradeData)
            return ethereumKit.estimateGas(
                            to: transactionData.to,
                            amount: transactionData.value == 0 ? nil : transactionData.value,
                            gasPrice: gasPrice,
                            data: transactionData.input
                    ).flatMap { [unowned self] gasLimit -> Single<TransactionWithInternal> in
                        print("GAS LIMIT SUCCESS: \(gasLimit)")
                        return ethereumKit.sendSingle(
                                address: transactionData.to,
                                value: transactionData.value,
                                transactionInput: transactionData.input,
                                gasPrice: gasPrice,
                                gasLimit: gasLimit)
                    }
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { transactionWithInternal in
                        print("SUCCESS: \(transactionWithInternal.transaction.hash.toHexString())")
                    }, onError: { error in
                        print("ERROR: \(error)")
                    })
                    .disposed(by: disposeBag)
        } catch {
            print("ERROR: \(error)")
        }
    }

}

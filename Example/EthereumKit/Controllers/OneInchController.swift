import UIKit
import EthereumKit
import RxSwift
import SnapKit
import UniswapKit
import OneInchKit
import BigInt

class OneInchController: UIViewController {
    private let disposeBag = DisposeBag()
    private var swapDisposeBag = DisposeBag()

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

    private var allowance: Decimal?

    private let gasPrice = 40_000_000_000

    private let signer = Manager.shared.signer
    private let ethereumKit = Manager.shared.evmKit!
    private let fromAdapter: IAdapter = Manager.shared.erc20Adapters[0]
    private let toAdapter: IAdapter = Manager.shared.ethereumAdapter

    private var fromToken: Erc20Token? { erc20Token(adapter: fromAdapter) }
    private var toToken: Erc20Token? { erc20Token(adapter: toAdapter) }

    private func erc20Token(adapter: IAdapter) -> Erc20Token? {
        guard let erc20Adapter = adapter as? Erc20Adapter else {
            return nil
        }

        return erc20Adapter.token
    }

    private var swapAdapter: ISwapAdapter
    private var inputFieldSwapAdapter: IInputFieldSwapAdapter?

    public init(swapAdapter: ISwapAdapter, inputFieldSwapAdapter: IInputFieldSwapAdapter?) {
        self.swapAdapter = swapAdapter
        self.inputFieldSwapAdapter = inputFieldSwapAdapter

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    private func pathString(path: [SwapToken]) -> String {
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
        let tradeType: TradeType = (inputFieldSwapAdapter?.exactIn ?? true) ? .exactIn : .exactOut

        fromLabel.text = "From:\(tradeType == .exactOut ? " (estimated)" : "")"
        toLabel.text = "To:\(tradeType == .exactIn ? " (estimated)" : "")"

        if let tradeData = swapAdapter.tradeData {
            switch tradeType {
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

        let amountIn = swapAdapter.tradeData?.amountIn ?? 0

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

        approveButton.isHidden = swapAdapter.tradeData == nil || !allowanceRequired

        let balanceSufficient = amountIn <= fromAdapter.balance

        swapButton.isHidden = swapAdapter.tradeData == nil || allowanceRequired || !balanceSufficient
    }

    private func tokenCoin(token: Erc20Token?) -> String {
        token?.coin ?? "ETH"
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

        fromAdapter.allowanceSingle(spenderAddress: swapAdapter.routerAddress)
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
        swapAdapter.tokenIn = swapAdapter.swapToken(token: fromToken)
        swapAdapter.tokenOut = swapAdapter.swapToken(token: toToken)

        swapAdapter.tradeDataObservable
                .subscribeOn(MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] tradeData in
                    self?.toTextField.text = tradeData?.amountOut?.description
                    self?.syncControls()
                })
                .disposed(by: disposeBag)
    }

    @objc private func onChangeAmountIn() {
        inputFieldSwapAdapter?.exactIn = true
        guard let amountIn = amount(textField: fromTextField) else {
            toTextField.text = nil
            swapAdapter.amount = nil
            syncControls()
            return
        }

        swapAdapter.amount = amountIn
        syncControls()
    }

    @objc private func onChangeAmountOut() {
        inputFieldSwapAdapter?.exactIn = false

        guard let amountOut = amount(textField: toTextField) else {
            fromTextField.text = nil
            swapAdapter.amount = nil
            syncControls()
            return
        }

        swapAdapter.amount = amountOut
        syncControls()
    }

    @objc private func onTapApprove() {
        guard let adapter = fromAdapter as? Erc20Adapter, let token = fromToken else {
            return
        }

        guard let decimalAmount = amount(textField: fromTextField), let amount = BigUInt(decimalAmount.roundedString(decimal: token.decimal)) else {
            return
        }

        let gasPrice = self.gasPrice
        let spenderAddress = swapAdapter.routerAddress

        let transactionData = adapter.erc20Kit.approveTransactionData(spenderAddress: spenderAddress, amount: amount)

        guard let signer = signer else {
            return
        }

        ethereumKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)
                .flatMap { [weak self] gasLimit -> Single<RawTransaction> in
                    guard let strongSelf = self else {
                        throw Signer.SendError.weakReferenceError
                    }

                    print("GAS LIMIT SUCCESS: \(gasLimit)")
                    return strongSelf.ethereumKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                }
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw Signer.SendError.weakReferenceError
                    }

                    let signature = try signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.ethereumKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { (tx: FullTransaction) in
                    print("SUCCESS: \(tx.transaction.hash.toHexString())")
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func swap(transactionData: TransactionData) {
        guard let signer = signer else {
            return
        }

        return ethereumKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)
                .flatMap { [weak self] gasLimit in
                    guard let strongSelf = self else {
                        throw Signer.SendError.weakReferenceError
                    }

                    print("GAS LIMIT SUCCESS: \(gasLimit)")
                    return strongSelf.ethereumKit.rawTransaction(transactionData: transactionData, gasPrice: strongSelf.gasPrice, gasLimit: gasLimit)
                }
                .flatMap { [weak self] (rawTransaction: RawTransaction) in
                    guard let strongSelf = self else {
                        throw Signer.SendError.weakReferenceError
                    }

                    let signature = try signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.ethereumKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { (tx: FullTransaction) in
                    print("SUCCESS: \(tx.transaction.hash.toHexString())")
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: disposeBag)
    }

    @objc private func onTapSwap() {
        swapDisposeBag = DisposeBag()

        swapAdapter.transactionData()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transactionData in
                    self?.swap(transactionData: transactionData)
                }, onError: { error in
                    print("ERROR: \(error)")
                })
                .disposed(by: swapDisposeBag)
    }

}

import RealmSwift

public class EthereumGasPrice: Object {
    static let normalGasPrice = 10_000_000_000

    @objc private dynamic var key: String = "gas_price"
    @objc public dynamic var gasPrice: Int = 0

    override public class func primaryKey() -> String? {
        return "key"
    }

    convenience init(gasPrice: Int = EthereumGasPrice.normalGasPrice) {
        self.init()
        self.gasPrice = gasPrice
    }

}

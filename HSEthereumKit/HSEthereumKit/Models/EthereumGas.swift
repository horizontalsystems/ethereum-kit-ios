import Foundation
import RealmSwift

public class EthereumGas: Object {
    public static let normalGasPriceInGWei = 41
    public static let normalGasLimit = 21000

    @objc public dynamic var address: String = ""
    @objc public dynamic var gasPriceGWei: Int = EthereumGas.normalGasPriceInGWei
    @objc public dynamic var gasLimit: Int = EthereumGas.normalGasLimit

    override public class func primaryKey() -> String? {
        return "address"
    }

    convenience init(address: String, priceInGWei: Int = EthereumGas.normalGasPriceInGWei, limit: Int = EthereumGas.normalGasLimit) {
        self.init()
        self.address = address
        update(priceInGWei: gasPriceGWei, limit: limit)
    }

    func update(priceInGWei: Int, limit: Int = EthereumGas.normalGasLimit) {
        self.gasPriceGWei = priceInGWei
        self.gasLimit = limit
    }

}

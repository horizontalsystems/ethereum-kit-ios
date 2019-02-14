import Foundation
import RealmSwift

public class EthereumBalance: Object {

    @objc public dynamic var address: String = ""
    @objc public dynamic var decimal: Int = 0
    @objc public dynamic var value: String = ""

    override class public func primaryKey() -> String? {
        return "address"
    }

    convenience init(address: String, decimal: Int, balance: Balance) {
        self.init()
        self.address = address
        self.decimal = decimal
        value = balance.wei.asString(withBase: 10)
    }

}

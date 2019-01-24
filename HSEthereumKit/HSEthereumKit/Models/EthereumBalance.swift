import Foundation
import RealmSwift

class EthereumBalance: Object {

    @objc dynamic var address: String = ""
    @objc dynamic var value: String = ""

    override class func primaryKey() -> String? {
        return "address"
    }

    convenience init(address: String, decimal: Int, balance: Balance) {
        self.init()
        self.address = address
        self.decimal = decimal
        value = balance.wei.asString(withBase: 10)
    }

}

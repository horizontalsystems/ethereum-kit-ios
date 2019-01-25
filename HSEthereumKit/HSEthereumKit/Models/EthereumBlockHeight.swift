import Foundation
import RealmSwift

class EthereumBlockHeight: Object {

    @objc private dynamic var key: String = ""
    @objc dynamic var blockHeight: Int = 0

    override class func primaryKey() -> String? {
        return "key"
    }

    convenience init(blockHeight: Int) {
        self.init()
        self.blockHeight = blockHeight
    }

}

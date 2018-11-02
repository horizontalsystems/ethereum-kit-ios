import Foundation
import RealmSwift

class EthereumBlockHeight: Object {
    static let key = "lastBlockHeight"

    @objc private dynamic var blockKey: String = EthereumBlockHeight.key
    @objc dynamic var blockHeight: Int = 0

    override class func primaryKey() -> String? {
        return "blockKey"
    }

    convenience init(blockHeight: Int) {
        self.init()

        self.blockHeight = blockHeight
    }

}

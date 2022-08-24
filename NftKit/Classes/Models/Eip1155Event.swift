import GRDB
import BigInt
import EthereumKit

class Eip1155Event: Record {
    let hash: Data
    let blockNumber: Int
    let contractAddress: Address
    let from: Address
    let to: Address
    let tokenId: BigUInt
    let tokenValue: Int
    let tokenName: String
    let tokenSymbol: String

    init(hash: Data, blockNumber: Int, contractAddress: Address, from: Address, to: Address, tokenId: BigUInt, tokenValue: Int, tokenName: String, tokenSymbol: String) {
        self.hash = hash
        self.blockNumber = blockNumber
        self.contractAddress = contractAddress
        self.from = from
        self.to = to
        self.tokenId = tokenId
        self.tokenValue = tokenValue
        self.tokenName = tokenName
        self.tokenSymbol = tokenSymbol

        super.init()
    }

    override class var databaseTableName: String {
        "eip1155Events"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case blockNumber
        case contractAddress
        case from
        case to
        case tokenId
        case tokenValue
        case tokenName
        case tokenSymbol
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        blockNumber = row[Columns.blockNumber]
        contractAddress = Address(raw: row[Columns.contractAddress])
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        tokenId = row[Columns.tokenId]
        tokenValue = row[Columns.tokenValue]
        tokenName = row[Columns.tokenName]
        tokenSymbol = row[Columns.tokenSymbol]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.blockNumber] = blockNumber
        container[Columns.contractAddress] = contractAddress.raw
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.tokenId] = tokenId
        container[Columns.tokenValue] = tokenValue
        container[Columns.tokenName] = tokenName
        container[Columns.tokenSymbol] = tokenSymbol
    }

}

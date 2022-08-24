import GRDB
import BigInt
import EthereumKit

class Eip721Event: Record {
    let hash: Data
    let blockNumber: Int
    let contractAddress: Address
    let from: Address
    let to: Address
    let tokenId: BigUInt
    let tokenName: String
    let tokenSymbol: String
    let tokenDecimal: Int

    init(hash: Data, blockNumber: Int, contractAddress: Address, from: Address, to: Address, tokenId: BigUInt, tokenName: String, tokenSymbol: String, tokenDecimal: Int) {
        self.hash = hash
        self.blockNumber = blockNumber
        self.contractAddress = contractAddress
        self.from = from
        self.to = to
        self.tokenId = tokenId
        self.tokenName = tokenName
        self.tokenSymbol = tokenSymbol
        self.tokenDecimal = tokenDecimal

        super.init()
    }

    override class var databaseTableName: String {
        "eip721Events"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case blockNumber
        case contractAddress
        case from
        case to
        case tokenId
        case tokenName
        case tokenSymbol
        case tokenDecimal
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        blockNumber = row[Columns.blockNumber]
        contractAddress = Address(raw: row[Columns.contractAddress])
        from = Address(raw: row[Columns.from])
        to = Address(raw: row[Columns.to])
        tokenId = row[Columns.tokenId]
        tokenName = row[Columns.tokenName]
        tokenSymbol = row[Columns.tokenSymbol]
        tokenDecimal = row[Columns.tokenDecimal]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.blockNumber] = blockNumber
        container[Columns.contractAddress] = contractAddress.raw
        container[Columns.from] = from.raw
        container[Columns.to] = to.raw
        container[Columns.tokenId] = tokenId
        container[Columns.tokenName] = tokenName
        container[Columns.tokenSymbol] = tokenSymbol
        container[Columns.tokenDecimal] = tokenDecimal
    }

}

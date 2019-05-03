import GRDB
import BigInt

class BlockHeader: Record {

    static let EMPTY_TRIE_HASH = CryptoUtils.shared.sha3(RLP.encode([]))

    var hashHex: Data
    var totalDifficulty: BigUInt = 0 // Scalar value corresponding to the sum of difficulty values of all previous blocks

    var parentHash: Data         // 256-bit Keccak-256 hash of parent block
    let unclesHash: Data         // 256-bit Keccak-256 hash of uncles portion of this block
    let coinbase: Data           // 160-bit address for fees collected from successful mining
    let stateRoot: Data          // 256-bit state trie root hash
    let transactionsRoot: Data    // 256-bit transactions trie root hash
    let receiptsRoot: Data       // 256-bit receipts trie root hash
    let logsBloom: Data          /* The Bloom filter composed from indexable information
                                  * (logger address and log topics) contained in each log entry
                                  * from the receipt of each transaction in the transactions list */
    let difficulty: BigUInt         /* A scalar value corresponding to the difficulty level of this block.
                                  * This can be calculated from the previous block’s difficulty level
                                  * and the timestamp */
    var height: Int
    let gasLimit: Int           // A scalar value equal to the current limit of gas expenditure per block
    let gasUsed: Int             // A scalar value equal to the total gas used in transactions in this block
    let timestamp: Int           // A scalar value equal to the reasonable output of Unix's time() at this block's inception
    let extraData: Data          /* An arbitrary byte array containing data relevant to this block.
                                  * With the exception of the genesis block, this must be 32 bytes or fewer */
    let mixHash: Data            /* A 256-bit hash which proves that together with nonce a sufficient amount
                                  * of computation has been carried out on this block */
    let nonce: Data              /* A 64-bit hash which proves that a sufficient amount
                                  * of computation has been carried out on this block */

    init(hashHex: Data, totalDifficulty: BigUInt, parentHash: Data, unclesHash: Data, coinbase: Data,
         stateRoot: Data, transactionsRoot: Data, receiptsRoot: Data, logsBloom: Data,
         difficulty: BigUInt, height: Int, gasLimit: Int, gasUsed: Int, timestamp: Int,
         extraData: Data, mixHash: Data, nonce: Data) {
        self.hashHex = hashHex
        self.totalDifficulty = totalDifficulty
        self.parentHash = parentHash
        self.unclesHash = unclesHash
        self.coinbase = coinbase
        self.stateRoot = stateRoot
        self.transactionsRoot = transactionsRoot
        self.receiptsRoot = receiptsRoot
        self.logsBloom = logsBloom
        self.difficulty = difficulty
        self.height = height
        self.gasLimit = gasLimit
        self.gasUsed = gasUsed
        self.timestamp = timestamp
        self.extraData = extraData
        self.mixHash = mixHash
        self.nonce = nonce

        super.init()
    }

    init(rlp: RLPElement) throws {
        let rlpList = try rlp.listValue()

        self.parentHash = rlpList[0].dataValue
        self.unclesHash = rlpList[1].dataValue
        self.coinbase = rlpList[2].dataValue
        self.stateRoot = rlpList[3].dataValue

        let transactionsRoot = rlpList[4].dataValue
        if transactionsRoot.count == 0 {
            self.transactionsRoot = BlockHeader.EMPTY_TRIE_HASH
        } else {
            self.transactionsRoot = transactionsRoot
        }

        let receiptsRoot = rlpList[5].dataValue
        if receiptsRoot.count == 0 {
            self.receiptsRoot = BlockHeader.EMPTY_TRIE_HASH
        } else {
            self.receiptsRoot = receiptsRoot
        }

        self.logsBloom = rlpList[6].dataValue
        self.difficulty = try rlpList[7].bigIntValue()
        self.height = try rlpList[8].intValue()
        self.gasLimit = try rlpList[9].intValue()
        self.gasUsed = try rlpList[10].intValue()
        self.timestamp = try rlpList[11].intValue()
        self.extraData = rlpList[12].dataValue
        self.mixHash = rlpList[13].dataValue
        self.nonce = rlpList[14].dataValue

        self.hashHex = CryptoUtils.shared.sha3(rlp.dataValue)

        super.init()
    }

    override class var databaseTableName: String {
        return "block_headers"
    }

    enum Columns: String, ColumnExpression {
        case hashHex
        case totalDifficulty
        case parentHash
        case unclesHash
        case coinbase
        case stateRoot
        case transactionsRoot
        case receiptsRoot
        case logsBloom
        case difficulty
        case height
        case gasLimit
        case gasUsed
        case timestamp
        case extraData
        case mixHash
        case nonce
    }

    required init(row: Row) {
        hashHex = row[Columns.hashHex]
        totalDifficulty = row[Columns.totalDifficulty]
        parentHash = row[Columns.parentHash]
        unclesHash = row[Columns.unclesHash]
        coinbase = row[Columns.coinbase]
        stateRoot = row[Columns.stateRoot]
        transactionsRoot = row[Columns.transactionsRoot]
        receiptsRoot = row[Columns.receiptsRoot]
        logsBloom = row[Columns.logsBloom]
        difficulty = row[Columns.difficulty]
        height = row[Columns.height]
        gasLimit = row[Columns.gasLimit]
        gasUsed = row[Columns.gasUsed]
        timestamp = row[Columns.timestamp]
        extraData = row[Columns.extraData]
        mixHash = row[Columns.mixHash]
        nonce = row[Columns.nonce]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.hashHex] = hashHex
        container[Columns.totalDifficulty] = totalDifficulty
        container[Columns.parentHash] = parentHash
        container[Columns.unclesHash] = unclesHash
        container[Columns.coinbase] = coinbase
        container[Columns.stateRoot] = stateRoot
        container[Columns.transactionsRoot] = transactionsRoot
        container[Columns.receiptsRoot] = receiptsRoot
        container[Columns.logsBloom] = logsBloom
        container[Columns.difficulty] = difficulty
        container[Columns.height] = height
        container[Columns.gasLimit] = gasLimit
        container[Columns.gasUsed] = gasUsed
        container[Columns.timestamp] = timestamp
        container[Columns.extraData] = extraData
        container[Columns.mixHash] = mixHash
        container[Columns.nonce] = nonce
    }

    func toString() -> String {
        return "(hash: \(hashHex.toHexString()); height: \(height); parentHash: \(parentHash.toHexString()))"
    }

}

import Foundation
import HSCryptoKit

class BlockHeader {

    static let EMPTY_TRIE_HASH = CryptoKit.sha3(RLP.encode([]))

    let hashHex: Data
    var totalDifficulty = Data() // Scalar value corresponding to the sum of difficulty values of all previous blocks


    let parentHash: Data         // 256-bit Keccak-256 hash of parent block
    let unclesHash: Data         // 256-bit Keccak-256 hash of uncles portion of this block
    let coinbase: Data           // 160-bit address for fees collected from successful mining
    let stateRoot: Data          // 256-bit state trie root hash
    let transactionsRoot: Data   // 256-bit transactions trie root hash
    let receiptsRoot: Data       // 256-bit receipts trie root hash
    let logsBloom: Data          /* The Bloom filter composed from indexable information
                                  * (logger address and log topics) contained in each log entry
                                  * from the receipt of each transaction in the transactions list */
    let difficulty: Data         /* A scalar value corresponding to the difficulty level of this block.
                                  * This can be calculated from the previous block’s difficulty level
                                  * and the timestamp */
    let height: BInt
    let gasLimit: Data           // A scalar value equal to the current limit of gas expenditure per block
    let gasUsed: Int             // A scalar value equal to the total gas used in transactions in this block
    let timestamp: Int           // A scalar value equal to the reasonable output of Unix's time() at this block's inception
    let extraData: Data          /* An arbitrary byte array containing data relevant to this block.
                                  * With the exception of the genesis block, this must be 32 bytes or fewer */
    let mixHash: Data            /* A 256-bit hash which proves that together with nonce a sufficient amount
                                  * of computation has been carried out on this block */
    let nonce: Data              /* A 64-bit hash which proves that a sufficient amount
                                  * of computation has been carried out on this block */

    init(hashHex: Data, totalDifficulty: Data, parentHash: Data, unclesHash: Data, coinbase: Data,
         stateRoot: Data, transactionsRoot: Data, receiptsRoot: Data, logsBloom: Data,
         difficulty: Data, height: BInt, gasLimit: Data, gasUsed: Int, timestamp: Int,
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
    }

    init(rlp: RLPElement) {
        self.parentHash = rlp.listValue[0].dataValue
        self.unclesHash = rlp.listValue[1].dataValue
        self.coinbase = rlp.listValue[2].dataValue
        self.stateRoot = rlp.listValue[3].dataValue

        let transactionsRoot = rlp.listValue[4].dataValue
        if transactionsRoot.count == 0 {
            self.transactionsRoot = BlockHeader.EMPTY_TRIE_HASH
        } else {
            self.transactionsRoot = transactionsRoot
        }

        let receiptsRoot = rlp.listValue[5].dataValue
        if receiptsRoot.count == 0 {
            self.receiptsRoot = BlockHeader.EMPTY_TRIE_HASH
        } else {
            self.receiptsRoot = receiptsRoot
        }

        self.logsBloom = rlp.listValue[6].dataValue
        self.difficulty = rlp.listValue[7].dataValue
        self.height = rlp.listValue[8].bIntValue
        self.gasLimit = rlp.listValue[9].dataValue
        self.gasUsed = rlp.listValue[10].intValue
        self.timestamp = rlp.listValue[11].intValue
        self.extraData = rlp.listValue[12].dataValue
        self.mixHash = rlp.listValue[13].dataValue
        self.nonce = rlp.listValue[14].dataValue

        self.hashHex = CryptoKit.sha3(rlp.dataValue)
    }

    func toString() -> String {
        return "(hash: \(hashHex.toHexString()); height: \(height); parentHash: \(parentHash.toHexString()))"
    }

}

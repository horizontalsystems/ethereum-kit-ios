import Foundation

class Block {

    let hashHex: Data
    let height: BInt
    let totalDifficulty: Data

    init(hashHex: Data, height: BInt, totalDifficulty: Data) {
        self.hashHex = hashHex
        self.height = height
        self.totalDifficulty = totalDifficulty
    }

}

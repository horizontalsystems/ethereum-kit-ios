import Foundation

class Ropsten: INetwork {

    let id = 3
    let genesisBlockHash = Data(hex: "41941023680923e0fe4d74a34bdac8141f2540e3ae90623718e47d66d1ca4a2d")

    let checkpointBlock = Block(
            hashHex: Data(hex: "b718dab7255a9a6221f34cc3bfdee6b427a6ee113a9b493c2137fafee06bd8e3"),
            height: BInt(4890000),
            totalDifficulty: Data(hex: String(18080483061023450, radix: 16))
    )

}

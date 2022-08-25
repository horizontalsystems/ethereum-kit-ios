import BigInt
import EthereumKit

public struct Nft {
    public let type: NftType
    public let contractAddress: Address
    public let tokenId: BigUInt
    public let tokenName: String

    init(type: NftType, contractAddress: Address, tokenId: BigUInt, tokenName: String) {
        self.type = type
        self.contractAddress = contractAddress
        self.tokenId = tokenId
        self.tokenName = tokenName
    }

}

extension Nft: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(contractAddress.raw)
        hasher.combine(tokenId)
    }

}

extension Nft: Equatable {

    public static func ==(lhs: Nft, rhs: Nft) -> Bool {
        lhs.type == rhs.type && lhs.contractAddress == rhs.contractAddress && lhs.tokenId == rhs.tokenId
    }

}

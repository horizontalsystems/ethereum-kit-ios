import EthereumKit
import BigInt

extension TransactionLog {

    public var eip721EventInstance: ContractEventInstance? {
        guard let signature = topics.first else {
            return nil
        }

        if signature == Eip721TransferEventInstance.signature, data.count == 96 {
            let from = data[0..<32]
            let to = data[32..<64]
            let tokenId = data[64..<96]

            return Eip721TransferEventInstance(
                    contractAddress: address,
                    from: Address(raw: from),
                    to: Address(raw: to),
                    tokenId: BigUInt(data)
            )
        }

        return nil
    }

    public var eip1155EventInstance: ContractEventInstance? {
        guard let signature = topics.first else {
            return nil
        }

        // todo

        return nil
    }

}

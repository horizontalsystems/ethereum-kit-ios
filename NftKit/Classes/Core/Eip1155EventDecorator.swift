import EthereumKit
import BigInt

class Eip1155EventDecorator {
    private let userAddress: Address
    private let storage: Storage

    init(userAddress: Address, storage: Storage) {
        self.userAddress = userAddress
        self.storage = storage
    }

}

extension Eip1155EventDecorator: IEventDecorator {

    public func contractEventInstancesMap(transactions: [Transaction]) -> [Data: [ContractEventInstance]] {
        let events: [Eip1155Event]

        do {
            if transactions.count > 100 {
                events = try storage.eip1155Events()
            } else {
                let hashes = transactions.map { $0.hash }
                events = try storage.eip1155Events(hashes: hashes)
            }
        } catch {
            events = []
        }

        var map = [Data: [ContractEventInstance]]()

        for event in events {
            let eventInstance = Eip1155TransferEventInstance(
                    contractAddress: event.contractAddress,
                    from: event.from,
                    to: event.to,
                    tokenId: event.tokenId,
                    value: BigUInt(event.tokenValue),
                    tokenInfo: event.tokenName.isEmpty && event.tokenSymbol.isEmpty ? nil : TokenInfo(tokenName: event.tokenName, tokenSymbol: event.tokenSymbol, tokenDecimal: 1)
            )

            map[event.hash] = (map[event.hash] ?? []) + [eventInstance]
        }

        return map
    }

    public func contractEventInstances(logs: [TransactionLog]) -> [ContractEventInstance] {
        logs.compactMap { log -> ContractEventInstance? in
            guard let eventInstance = log.eip1155EventInstance else {
                return nil
            }

            switch eventInstance {
            case let transfer as Eip1155TransferEventInstance:
                if transfer.from == userAddress || transfer.to == userAddress {
                    return eventInstance
                }

            default: ()
            }

            return nil
        }
    }

}

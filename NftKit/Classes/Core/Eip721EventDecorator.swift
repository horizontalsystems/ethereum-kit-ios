import EthereumKit

class Eip721EventDecorator {
    private let userAddress: Address
    private let storage: Storage

    init(userAddress: Address, storage: Storage) {
        self.userAddress = userAddress
        self.storage = storage
    }

}

extension Eip721EventDecorator: IEventDecorator {

    public func contractEventInstancesMap(transactions: [Transaction]) -> [Data: [ContractEventInstance]] {
        let events: [Eip721Event]

        do {
            if transactions.count > 100 {
                events = try storage.eip721Events()
            } else {
                let hashes = transactions.map { $0.hash }
                events = try storage.eip721Events(hashes: hashes)
            }
        } catch {
            events = []
        }

        var map = [Data: [ContractEventInstance]]()

        for event in events {
            let eventInstance = Eip721TransferEventInstance(
                    contractAddress: event.contractAddress,
                    from: event.from,
                    to: event.to,
                    tokenId: event.tokenId,
                    tokenInfo: event.tokenName.isEmpty && event.tokenSymbol.isEmpty ? nil : TokenInfo(tokenName: event.tokenName, tokenSymbol: event.tokenSymbol, tokenDecimal: event.tokenDecimal)
            )

            map[event.hash] = (map[event.hash] ?? []) + [eventInstance]
        }

        return map
    }

    public func contractEventInstances(logs: [TransactionLog]) -> [ContractEventInstance] {
        logs.compactMap { log -> ContractEventInstance? in
            guard let eventInstance = log.eip721EventInstance else {
                return nil
            }

            switch eventInstance {
            case let transfer as Eip721TransferEventInstance:
                if transfer.from == userAddress || transfer.to == userAddress {
                    return eventInstance
                }

            default: ()
            }

            return nil
        }
    }

}

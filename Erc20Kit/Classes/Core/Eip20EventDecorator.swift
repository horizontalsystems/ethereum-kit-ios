import EthereumKit

class Eip20EventDecorator {
    private let userAddress: Address
    private let evmKit: EthereumKit.Kit

    init(userAddress: Address, evmKit: EthereumKit.Kit) {
        self.userAddress = userAddress
        self.evmKit = evmKit
    }

}

extension Eip20EventDecorator: IEventDecorator {

    public func contractEventInstancesMap(transactions: [Transaction]) -> [Data: [ContractEventInstance]] {
        let events: [Event]

        if transactions.count > 100 {
            events = evmKit.events()
        } else {
            let hashes = transactions.map { $0.hash }
            events = evmKit.events(hashes: hashes)
        }

        var map = [Data: [ContractEventInstance]]()

        for event in events {
            let eventInstance = TransferEventInstance(
                    contractAddress: event.contractAddress,
                    from: event.from,
                    to: event.to,
                    value: event.value,
                    tokenInfo: TransferEventInstance.TokenInfo(tokenName: event.tokenName, tokenSymbol: event.tokenSymbol, tokenDecimal: event.tokenDecimal)
            )

            map[event.hash] = (map[event.hash] ?? []) + [eventInstance]
        }

        return map
    }

    public func contractEventInstances(logs: [TransactionLog]) -> [ContractEventInstance] {
        logs.compactMap { log -> ContractEventInstance? in
            guard let eventInstance = log.erc20EventInstance else {
                return nil
            }

            switch eventInstance {
            case let transfer as TransferEventInstance:
                if transfer.from == userAddress || transfer.to == userAddress {
                    return eventInstance
                }

            case let approve as ApproveEventInstance:
                if approve.owner == userAddress || approve.spender == userAddress {
                    return eventInstance
                }

            default: ()
            }

            return nil
        }
    }

}

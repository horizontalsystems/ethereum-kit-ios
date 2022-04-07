import BigInt

class EthereumDecorator {
    private let address: Address

    init(address: Address) {
        self.address = address
    }

}

extension EthereumDecorator: ITransactionDecorator {

    public func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration? {
        guard let from = from, let value = value, let contractMethod = contractMethod else {
            return nil
        }

        guard let to = to else {
            return ContractCreationDecoration()
        }

        guard contractMethod is EmptyMethod else {
            return nil
        }

        if from == address {
            return OutgoingDecoration(to: to, value: value, sentToSelf: to == address)
        }

        if to == address {
            return IncomingDecoration(from: from, value: value)
        }

        return nil
    }

}

import EthereumKit
import BigInt

public class OneInchUnknownSwapDecoration: UnknownTransactionDecoration {
    public let contractAddress: Address
    public let value: BigUInt

    init(contractAddress: Address, userAddress: Address, value: BigUInt, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) {
        self.contractAddress = contractAddress
        self.value = value

        super.init(userAddress: userAddress, value: value, internalTransactions: internalTransactions, eventInstances: eventInstances)
    }

    public override func tags() -> [String] {
        super.tags() + [contractAddress.hex, "swap"]
    }

}

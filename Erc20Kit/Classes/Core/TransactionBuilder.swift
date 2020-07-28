import EthereumKit
import BigInt

class TransactionBuilder: ITransactionBuilder {

    func transferTransactionInput(to toAddress: Address, value: BigUInt) -> Data {
        ContractMethod(name: "transfer", arguments: [.address(toAddress), .uint256(value)]).encodedData
    }

}

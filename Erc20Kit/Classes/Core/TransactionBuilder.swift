import EthereumKit
import BigInt

class TransactionBuilder: ITransactionBuilder {

    func transferTransactionInput(to toAddress: Address, value: BigUInt) -> Data {
        TransferMethod(to: toAddress, value: value).encodedABI()
    }

}

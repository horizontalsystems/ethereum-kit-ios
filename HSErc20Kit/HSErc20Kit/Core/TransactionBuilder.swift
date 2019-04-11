import HSEthereumKit

class TransactionBuilder {

    func transferTransactionInput(to toAddress: Data, value: BInt) -> Data {
        return ERC20.ContractFunctions.transfer(address: toAddress, amount: value).data
    }

}

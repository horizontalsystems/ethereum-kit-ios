import BigInt

class TransactionBuilder: ITransactionBuilder {

    func transferTransactionInput(to toAddress: Data, value: BigUInt) -> Data {
        ERC20.ContractFunctions.transfer(address: toAddress, amount: value).data
    }

}

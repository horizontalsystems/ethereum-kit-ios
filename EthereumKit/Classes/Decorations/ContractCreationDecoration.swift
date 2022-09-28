public class ContractCreationDecoration: TransactionDecoration {

    public override func tags() -> [TransactionTag] {
        [
            TransactionTag(type: .contractCreation)
        ]
    }

}

import Foundation

public struct FullRpcTransaction {
    public let rpcTransaction: RpcTransaction
    public let rpcTransactionReceipt: RpcTransactionReceipt
    public let rpcBlock: RpcBlock
    public let internalTransactions: [InternalTransaction]

    private var failed: Bool {
        if let status = rpcTransactionReceipt.status {
            return status == 0
        } else {
            return rpcTransaction.gasLimit == rpcTransactionReceipt.gasUsed
        }
    }

    var transaction: Transaction {
        Transaction(
                hash: rpcTransaction.hash,
                timestamp: rpcBlock.timestamp,
                isFailed: failed,
                blockNumber: rpcBlock.number,
                transactionIndex: rpcTransactionReceipt.transactionIndex,
                from: rpcTransaction.from,
                to: rpcTransaction.to,
                value: rpcTransaction.value,
                input: rpcTransaction.input,
                nonce: rpcTransaction.nonce,
                gasPrice: rpcTransaction.gasPrice,
                maxFeePerGas: rpcTransaction.maxFeePerGas,
                maxPriorityFeePerGas: rpcTransaction.maxPriorityFeePerGas,
                gasLimit: rpcTransaction.gasLimit,
                gasUsed: rpcTransactionReceipt.gasUsed
        )
    }

}

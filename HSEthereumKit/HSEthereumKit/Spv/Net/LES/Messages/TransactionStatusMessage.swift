class TransactionStatusMessage: IInMessage {
    let requestId: Int
    let bv: Int
    let statuses: [TransactionStatus]

    required init(data: Data) throws {
        let rlpList = try RLP.decode(input: data).listValue()

        guard rlpList.count >= 3 else {
            throw MessageDecodeError.notEnoughFields
        }

        requestId = try rlpList[0].intValue()
        bv = try rlpList[1].intValue()

        statuses = try rlpList[2].listValue().map { statusData -> TransactionStatus in
            let statusList = try statusData.listValue()

            let statusCode = try statusList[0].intValue()

            switch statusCode {
            case 1: return .queued
            case 2: return .pending
            case 3:
                let dataList = try statusList[1].listValue()

                return .included(
                        blockHash: dataList[0].dataValue,
                        blockNumber: try dataList[1].intValue(),
                        transactionIndex: try dataList[2].intValue()
                )
            case 4:
                return .error(message: try statusList[1].stringValue())
            default: return .unknown
            }
        }
    }

    func toString() -> String {
        return "TX_STATUS [requestId: \(requestId), bv: \(bv), statuses: \(statuses)]"
    }

}

extension TransactionStatusMessage {

    enum TransactionStatus {
        case unknown
        case queued
        case pending
        case included(blockHash: Data, blockNumber: Int, transactionIndex: Int)
        case error(message: String)
    }

}

class GetTransactionStatusMessage: IOutMessage {
    var requestId = 0

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_TX_STATUS []"
    }

}

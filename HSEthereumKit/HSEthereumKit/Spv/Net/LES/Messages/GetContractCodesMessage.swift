class GetContractCodesMessage: IOutMessage {
    var requestId = 0

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_CONTRACT_CODES []"
    }

}

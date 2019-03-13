class GetBlockBodiesMessage: IOutMessage {
    var requestId = 0

    func encoded() -> Data {
        return Data()
    }

    func toString() -> String {
        return "GET_BLOCK_BODIES []"
    }

}

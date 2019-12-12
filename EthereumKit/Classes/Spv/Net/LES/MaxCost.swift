class MaxCost {
    let messageCode: Int
    let baseCost: Int
    let requestCost: Int

    init(rlp: RLPElement) throws {
        let list = try rlp.listValue()

        messageCode = try list[0].intValue()
        baseCost = try list[1].intValue()
        requestCost = try list[2].intValue()
    }

    func toString() -> String {
        return "MAX_COST [messageCode: \(String(format: "0x%02X", messageCode)); baseCost: \(baseCost.flowControlLog); requestCost: \(requestCost.flowControlLog)]"
    }

}

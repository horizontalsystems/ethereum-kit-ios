class Frame {
    static let minSize = 64

    let type: Int
    let payloadSize: Int
    let payload: Data

    var contextId = -1
    var allFramesTotalSize = -1
    var size = 0

    convenience init(type: Int, payload: Data, size: Int, contextId: Int, allFramesTotalSize: Int) {
        self.init(type: type, payload: payload, contextId: contextId, allFramesTotalSize: allFramesTotalSize)
        self.size = size
    }

    init(type: Int, payload: Data, contextId: Int, allFramesTotalSize: Int) {
        self.type = type
        self.payload = payload
        self.payloadSize = payload.count
        self.contextId = contextId
        self.allFramesTotalSize = allFramesTotalSize
    }

}

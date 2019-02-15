
protocol IMessage {

    var code: Int { get }
    func encoded() -> Data
    func toString() -> String

}


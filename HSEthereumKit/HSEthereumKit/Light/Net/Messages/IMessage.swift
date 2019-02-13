
protocol IMessage {

    var code: Int { get }
    func encoded() -> Data

}


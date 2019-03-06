class MessageFactory: IMessageFactory {

    func helloMessage(key: ECKey, capabilities: [Capability]) -> IHelloMessage {
        return HelloMessage(peerId: key.publicKeyPoint.x + key.publicKeyPoint.y, port: 30303, capabilities: capabilities)
    }

    func pongMessage() -> IPongMessage {
        return PongMessage()
    }

}

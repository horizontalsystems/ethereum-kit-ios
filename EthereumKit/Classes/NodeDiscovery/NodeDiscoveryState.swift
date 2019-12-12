class NodeDiscoveryState {
    private let queue = DispatchQueue(label: "NodeDiscovery.State", qos: .utility)
    private(set) var clients = [IUdpClient]()

    func add(client: IUdpClient) {
        queue.sync {
            self.clients.append(client)
        }
    }

    func remove(client: IUdpClient) {
        queue.sync {
            self.clients.removeAll(where: { $0.id == client.id })
        }
    }

    func removeAll() {
        queue.sync {
            self.clients.removeAll()
        }
    }

}
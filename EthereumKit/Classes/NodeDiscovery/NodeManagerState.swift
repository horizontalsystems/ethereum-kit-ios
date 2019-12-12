class NodeManagerState {
    private let queue = DispatchQueue(label: "NodeManager.State", qos: .utility)
    private(set) var usedIds: [Data] = []

    func add(usedId: Data) {
        queue.sync {
            self.usedIds.append(usedId)
        }
    }

    func remove(usedId: Data) {
        queue.sync {
            self.usedIds.removeAll(where: { $0 == usedId })
        }
    }

    func removeAll() {
        queue.sync {
            self.usedIds.removeAll()
        }
    }

}
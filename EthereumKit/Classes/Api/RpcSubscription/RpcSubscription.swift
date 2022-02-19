class RpcSubscription<T> {
    let params: [Any]

    init(params: [Any]) {
        self.params = params
    }

    func parse(result: Any) throws -> T {
        fatalError("This method should be overridden")
    }

}

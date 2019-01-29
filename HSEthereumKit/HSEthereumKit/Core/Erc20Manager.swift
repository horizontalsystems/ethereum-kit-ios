protocol IErc20ManagerRefreshDelegate: class {
    func onRefresh(contractAddress: String)
    func onDisconnect(contractAddress: String)
}

extension IErc20ManagerRefreshDelegate {

    func onDisconnect(contractAddress: String) {
        // Do nothing
    }

}

class Erc20Manager {
    private(set) var holders = [Erc20Holder]()
    private let reachabilityManager: IReachabilityManager

    weak var delegate: IErc20ManagerRefreshDelegate?

    init(reachabilityManager: IReachabilityManager, delegate: IErc20ManagerRefreshDelegate? = nil) {
        self.reachabilityManager = reachabilityManager
        self.delegate = delegate
    }

    func enable(contractAddress: String, decimal: Int) {
        guard holders.firstIndex(where: { erc20Holder in contractAddress == erc20Holder.erc20.contractAddress }) == nil else {
            return
        }

        let erc20Holder = Erc20Holder(address: contractAddress, decimal: decimal, reachabilityManager: reachabilityManager)
        erc20Holder.refresh = { [weak self] in
            self?.delegate?.onRefresh(contractAddress: contractAddress)
        }
        erc20Holder.disconnect = { [weak self] in
            self?.delegate?.onDisconnect(contractAddress: contractAddress)
        }

        holders.append(erc20Holder)
    }

    func disable(contractAddress: String) {
        if let index = holders.firstIndex(where: { erc20Holder in contractAddress == erc20Holder.erc20.contractAddress }) {
            holders[index].refresh = nil
            holders[index].disconnect = nil

            holders.remove(at: index)
        }
    }

    func holder(for address: String) -> Erc20Holder? {
        if let index = holders.firstIndex(where: { erc20Holder in address == erc20Holder.erc20.contractAddress }) {
            return holders[index]
        }
        return nil
    }

}

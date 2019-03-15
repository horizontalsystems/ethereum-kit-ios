class CapabilityHelper: ICapabilityHelper {

    func sharedCapabilities(myCapabilities: [Capability], nodeCapabilities: [Capability]) -> [Capability] {
        var sharedCapabilities = [Capability]()

        for myCapability in myCapabilities {
            if nodeCapabilities.contains(myCapability) {
                if let index = sharedCapabilities.firstIndex(where: { $0.name == myCapability.name }) {
                    if myCapability.version > sharedCapabilities[index].version {
                        sharedCapabilities[index] = myCapability
                    }
                } else {
                    sharedCapabilities.append(myCapability)
                }
            }
        }

        return sharedCapabilities.sorted(by: { $0.name < $1.name  })
    }

}

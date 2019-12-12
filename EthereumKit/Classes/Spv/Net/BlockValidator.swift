class BlockValidator {

    func validate(blockHeaders: [BlockHeader], from blockHeader: BlockHeader) throws {
        guard let firstBlockHeader = blockHeaders.first else {
            throw ValidationError.invalidChain
        }

        guard firstBlockHeader.hashHex == blockHeader.hashHex else {
            throw ValidationError.forkDetected
        }

        var previousHeader = blockHeader

        for blockHeader in blockHeaders.dropFirst() {
            guard blockHeader.parentHash == previousHeader.hashHex else {
                throw ValidationError.invalidChain
            }
            previousHeader = blockHeader
        }
    }

}

extension BlockValidator {

    enum ValidationError: Error {
        case forkDetected
        case invalidChain
        case invalidProofOfWork
    }

}

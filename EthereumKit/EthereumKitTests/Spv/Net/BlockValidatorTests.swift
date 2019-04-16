import XCTest
import Quick
import Nimble
import Cuckoo
@testable import EthereumKit

class BlockValidatorTests: QuickSpec {

    override func spec() {
        let validator = BlockValidator()

        let initialHash = Data(repeating: 1, count: 10)
        let secondHash = Data(repeating: 2, count: 10)
        let thirdHash = Data(repeating: 3, count: 10)
        let initialHeight = 100
        let secondHeight = 101
        let thirdHeight = 102

        let initialHeader = BlockHeader()

        let firstHeader = BlockHeader()
        let secondHeader = BlockHeader()
        let thirdHeader = BlockHeader()

        let headers = [firstHeader, secondHeader, thirdHeader]

        beforeEach {
            initialHeader.hashHex = initialHash
            initialHeader.height = initialHeight

            firstHeader.hashHex = initialHash
            firstHeader.height = initialHeight

            secondHeader.hashHex = secondHash
            secondHeader.parentHash = initialHash
            secondHeader.height = secondHeight

            thirdHeader.hashHex = thirdHash
            thirdHeader.parentHash = secondHash
            thirdHeader.height = thirdHeight
        }

        context("when blocks are valid") {
            it("does not throw any errors") {
                expect { try validator.validate(blockHeaders: headers, from: initialHeader) }.notTo(throwError())
            }
        }

        context("when block headers are empty") {
            it("throws invalidChain error") {
                expect { try validator.validate(blockHeaders: [], from: initialHeader) }.to(throwError(BlockValidator.ValidationError.invalidChain))
            }
        }

        context("when initial hashes are different") {
            beforeEach {
                initialHeader.hashHex = Data(repeating: 123, count: 10)
            }

            it("throws forkDetected error") {
                expect { try validator.validate(blockHeaders: headers, from: initialHeader) }.to(throwError(BlockValidator.ValidationError.forkDetected))
            }
        }

        context("when parent hash is invalid") {
            beforeEach {
                thirdHeader.parentHash = Data(repeating: 123, count: 10)
            }

            it("throws invalidChain error") {
                expect { try validator.validate(blockHeaders: headers, from: initialHeader) }.to(throwError(BlockValidator.ValidationError.invalidChain))
            }
        }
    }

}

import XCTest
import RxSwift
import Cuckoo
@testable import HSEthereumKit

class EthereumKitTests: XCTestCase {
    private var mockDelegate: MockIEthereumKitDelegate!
    private var mockBlockchain: MockIBlockchain!
    private var mockStorage: MockIStorage!
    private var mockAddressValidator: MockIAddressValidator!
    private var mockState: MockEthereumKitState!

    private var kit: EthereumKit!

    private let ethereumAddress = "ethereum_address"

    override func setUp() {
        super.setUp()

        mockDelegate = MockIEthereumKitDelegate()
        mockBlockchain = MockIBlockchain()
        mockStorage = MockIStorage()
        mockAddressValidator = MockIAddressValidator()
        mockState = MockEthereumKitState()

        stub(mockBlockchain) { mock in
            when(mock.ethereumAddress.get).thenReturn(ethereumAddress)
        }
        stub(mockStorage) { mock in
            when(mock.balance(forAddress: ethereumAddress)).thenReturn(nil)
            when(mock.lastBlockHeight.get).thenReturn(nil)
        }
        stub(mockState) { mock in
            when(mock.balance.set(any())).thenDoNothing()
            when(mock.lastBlockHeight.set(any())).thenDoNothing()
        }

        kit = createKit()
        kit.delegate = mockDelegate
    }

    private func createKit() -> EthereumKit {
        return EthereumKit(blockchain: mockBlockchain, storage: mockStorage, addressValidator: mockAddressValidator, state: mockState)
    }

    override func tearDown() {
        super.tearDown()

        mockDelegate = nil
        mockBlockchain = nil
        mockStorage = nil
        mockAddressValidator = nil
        mockState = nil

        kit = nil
    }

    func testInit_balance() {
        let balance = "12345"
        let lastBlockHeight = 123

        stub(mockStorage) { mock in
            when(mock.balance(forAddress: ethereumAddress)).thenReturn(balance)
            when(mock.lastBlockHeight.get).thenReturn(lastBlockHeight)
        }

        _ = createKit()

        verify(mockState).balance.set(equal(to: balance))
        verify(mockState).lastBlockHeight.set(equal(to: lastBlockHeight))
    }

    func testStart() {
        stub(mockBlockchain) { mock in
            when(mock.start()).thenDoNothing()
        }

        kit.start()

        verify(mockBlockchain).start()
    }

    func testClear() {
        stub(mockStorage) { mock in
            when(mock.clear()).thenDoNothing()
        }
        stub(mockState) { mock in
            when(mock.clear()).thenDoNothing()
        }
        stub(mockBlockchain) { mock in
            when(mock.clear()).thenDoNothing()
        }

        kit.clear()

        verify(mockBlockchain).clear()
        verify(mockStorage).clear()
        verify(mockState).clear()
    }

    func testReceiveAddress() {
        let ethereumAddress = "ethereum_address"

        stub(mockBlockchain) { mock in
            when(mock.ethereumAddress.get).thenReturn(ethereumAddress)
        }

        XCTAssertEqual(kit.receiveAddress, ethereumAddress)
    }

    func testRegister() {
        let balance = "12345"
        let contractAddress = "contract_address"
        let delegate = MockIEthereumKitDelegate()

        stub(mockState) { mock in
            when(mock.has(contractAddress: contractAddress)).thenReturn(false)
            when(mock.add(contractAddress: any(), delegate: any())).thenDoNothing()
            when(mock.set(balance: any(), contractAddress: any())).thenDoNothing()
        }
        stub(mockBlockchain) { mock in
            when(mock.register(contractAddress: any())).thenDoNothing()
        }
        stub(mockStorage) { mock in
            when(mock.balance(forAddress: contractAddress)).thenReturn(balance)
        }

        kit.register(contractAddress: contractAddress, delegate: delegate)

        verify(mockState).add(contractAddress: contractAddress, delegate: equal(to: delegate) { $0 === $1 })
        verify(mockState).set(balance: equal(to: balance), contractAddress: equal(to: contractAddress))
        verify(mockBlockchain).register(contractAddress: contractAddress)
    }

    func testRegister_alreadyRegistered() {
        let contractAddress = "contract_address"
        let delegate = MockIEthereumKitDelegate()

        stub(mockState) { mock in
            when(mock.has(contractAddress: contractAddress)).thenReturn(true)
            when(mock.add(contractAddress: any(), delegate: any())).thenDoNothing()
        }
        stub(mockBlockchain) { mock in
            when(mock.register(contractAddress: any())).thenDoNothing()
        }

        kit.register(contractAddress: contractAddress, delegate: delegate)

        verify(mockState, never()).add(contractAddress: any(), delegate: any())
        verify(mockBlockchain, never()).register(contractAddress: any())
    }

    func testUnregister() {
        let contractAddress = "contract_address"

        stub(mockState) { mock in
            when(mock.remove(contractAddress: any())).thenDoNothing()
        }
        stub(mockBlockchain) { mock in
            when(mock.unregister(contractAddress: any())).thenDoNothing()
        }

        kit.unregister(contractAddress: contractAddress)

        verify(mockState).remove(contractAddress: contractAddress)
        verify(mockBlockchain).unregister(contractAddress: contractAddress)
    }

    func testValidateAddress() {
        let address = "address"

        stub(mockAddressValidator) { mock in
            when(mock.validate(address: address)).thenDoNothing()
        }

        XCTAssertNoThrow(
                try kit.validate(address: address)
        )

        verify(mockAddressValidator).validate(address: address)
    }

    func testValidateAddress_error() {
        let address = "address"
        struct AddressError: Error {}

        stub(mockAddressValidator) { mock in
            when(mock.validate(address: address)).thenThrow(AddressError())
        }

        XCTAssertThrowsError(
            try kit.validate(address: address)
        )

        verify(mockAddressValidator).validate(address: address)
    }

    func testLastBlockHeight() {
        let lastBlockHeight = 123

        stub(mockState) { mock in
            when(mock.lastBlockHeight.get).thenReturn(lastBlockHeight)
        }

        XCTAssertEqual(kit.lastBlockHeight, lastBlockHeight)
    }

    func testBalance() {
        let balance = "12345"

        stub(mockState) { mock in
            when(mock.balance.get).thenReturn(balance)
        }

        XCTAssertEqual(kit.balance, balance)
    }

    func testSyncState() {
        let syncState: EthereumKit.SyncState = .synced

        stub(mockBlockchain) { mock in
            when(mock.syncState.get).thenReturn(syncState)
        }

        XCTAssertEqual(kit.syncState, syncState)
    }

    func testFee() {
        let gasPriceInWei = GasPrice(lowPriority: 123, mediumPriority: 12345, highPriority: 999999, date: Date())
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasPriceInWei(priority: equal(to: FeePriority.medium))).thenReturn(gasPriceInWei.mediumPriority)
            when(mock.gasLimitEthereum.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei.mediumPriority) * Decimal(gasLimit)

        XCTAssertEqual(kit.fee(), expectedFee)
    }

    func testFee_customGasPrice() {
        let gasPriceInWei = 23456
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasPriceInWei(priority: equal(to: FeePriority.medium))).thenReturn(gasPriceInWei)
            when(mock.gasLimitEthereum.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei) * Decimal(gasLimit)

        XCTAssertEqual(kit.fee(priority: .medium), expectedFee)
    }

    func testFeeErc20() {
        let gasPriceInWei = GasPrice(lowPriority: 123, mediumPriority: 12345, highPriority: 999999, date: Date())
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasPriceInWei(priority: equal(to: FeePriority.medium))).thenReturn(gasPriceInWei.mediumPriority)
            when(mock.gasLimitErc20.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei.mediumPriority) * Decimal(gasLimit)

        XCTAssertEqual(kit.feeErc20(), expectedFee)
    }

    func testFeeErc20_customGasPrice() {
        let gasPriceInWei = 23456
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasPriceInWei(priority: equal(to: FeePriority.medium))).thenReturn(gasPriceInWei)
            when(mock.gasLimitErc20.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei) * Decimal(gasLimit)

        XCTAssertEqual(kit.feeErc20(priority: .medium), expectedFee)
    }

    func testBalanceErc20() {
        let contractAddress = "contract_address"
        let balance = "12345"

        stub(mockState) { mock in
            when(mock.balance(contractAddress: contractAddress)).thenReturn(balance)
        }

        XCTAssertEqual(kit.balanceErc20(contractAddress: contractAddress), balance)
    }

    func testSyncStateErc20() {
        let contractAddress = "contract_address"
        let syncState: EthereumKit.SyncState = .synced

        stub(mockBlockchain) { mock in
            when(mock.syncState(contractAddress: contractAddress)).thenReturn(syncState)
        }

        XCTAssertEqual(kit.syncStateErc20(contractAddress: contractAddress), syncState)
    }

}

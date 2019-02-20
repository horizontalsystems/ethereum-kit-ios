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
        let balance: Decimal = 123.45
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

    func testStop() {
        stub(mockBlockchain) { mock in
            when(mock.stop()).thenDoNothing()
        }

        kit.stop()

        verify(mockBlockchain).stop()
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
        let balance: Decimal = 123.45
        let contractAddress = "contract_address"
        let decimal = 18
        let delegate = MockIEthereumKitDelegate()

        stub(mockState) { mock in
            when(mock.has(contractAddress: contractAddress)).thenReturn(false)
            when(mock.add(contractAddress: any(), decimal: any(), delegate: any())).thenDoNothing()
            when(mock.set(balance: any(), contractAddress: any())).thenDoNothing()
        }
        stub(mockBlockchain) { mock in
            when(mock.register(contractAddress: any(), decimal: any())).thenDoNothing()
        }
        stub(mockStorage) { mock in
            when(mock.balance(forAddress: contractAddress)).thenReturn(balance)
        }

        kit.register(contractAddress: contractAddress, decimal: decimal, delegate: delegate)

        verify(mockState).add(contractAddress: contractAddress, decimal: decimal, delegate: equal(to: delegate) { $0 === $1 })
        verify(mockState).set(balance: equal(to: balance), contractAddress: equal(to: contractAddress))
        verify(mockBlockchain).register(contractAddress: contractAddress, decimal: decimal)
    }

    func testRegister_alreadyRegistered() {
        let contractAddress = "contract_address"
        let decimal = 18
        let delegate = MockIEthereumKitDelegate()

        stub(mockState) { mock in
            when(mock.has(contractAddress: contractAddress)).thenReturn(true)
            when(mock.add(contractAddress: any(), decimal: any(), delegate: any())).thenDoNothing()
        }
        stub(mockBlockchain) { mock in
            when(mock.register(contractAddress: any(), decimal: any())).thenDoNothing()
        }

        kit.register(contractAddress: contractAddress, decimal: decimal, delegate: delegate)

        verify(mockState, never()).add(contractAddress: any(), decimal: any(), delegate: any())
        verify(mockBlockchain, never()).register(contractAddress: any(), decimal: any())
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
        let balance: Decimal = 123.45

        stub(mockState) { mock in
            when(mock.balance.get).thenReturn(balance)
        }

        XCTAssertEqual(kit.balance, balance)
    }

    func testBalance_default() {
        stub(mockState) { mock in
            when(mock.balance.get).thenReturn(nil)
        }

        XCTAssertEqual(kit.balance, 0)
    }

    func testSyncState() {
        let syncState: EthereumKit.SyncState = .synced

        stub(mockBlockchain) { mock in
            when(mock.syncState.get).thenReturn(syncState)
        }

        XCTAssertEqual(kit.syncState, syncState)
    }

    func testFee() {
        let gasPriceInWei = 12345
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasPriceInWei.get).thenReturn(gasPriceInWei)
            when(mock.gasLimitEthereum.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei) / pow(10, 18) * Decimal(gasLimit)

        XCTAssertEqual(kit.fee(), expectedFee)
    }

    func testFee_customGasPrice() {
        let gasPriceInWei = 23456
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasLimitEthereum.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei) / pow(10, 18) * Decimal(gasLimit)

        XCTAssertEqual(kit.fee(gasPriceInWei: gasPriceInWei), expectedFee)
    }

    func testFeeErc20() {
        let gasPriceInWei = 12345
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasPriceInWei.get).thenReturn(gasPriceInWei)
            when(mock.gasLimitErc20.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei) / pow(10, 18) * Decimal(gasLimit)

        XCTAssertEqual(kit.feeErc20(), expectedFee)
    }

    func testFeeErc20_customGasPrice() {
        let gasPriceInWei = 23456
        let gasLimit = 21_000

        stub(mockBlockchain) { mock in
            when(mock.gasLimitErc20.get).thenReturn(gasLimit)
        }

        let expectedFee = Decimal(gasPriceInWei) / pow(10, 18) * Decimal(gasLimit)

        XCTAssertEqual(kit.feeErc20(gasPriceInWei: gasPriceInWei), expectedFee)
    }

    func testBalanceErc20() {
        let contractAddress = "contract_address"
        let balance: Decimal = 123.45

        stub(mockState) { mock in
            when(mock.balance(contractAddress: contractAddress)).thenReturn(balance)
        }

        XCTAssertEqual(kit.balanceErc20(contractAddress: contractAddress), balance)
    }

    func testBalanceErc20_default() {
        let contractAddress = "contract_address"

        stub(mockState) { mock in
            when(mock.balance(contractAddress: contractAddress)).thenReturn(nil)
        }

        XCTAssertEqual(kit.balanceErc20(contractAddress: contractAddress), 0)
    }

    func testSyncStateErc20() {
        let contractAddress = "contract_address"
        let syncState: EthereumKit.SyncState = .synced

        stub(mockBlockchain) { mock in
            when(mock.syncState(contractAddress: contractAddress)).thenReturn(syncState)
        }

        XCTAssertEqual(kit.syncStateErc20(contractAddress: contractAddress), syncState)
    }

    func testOnUpdateLastBlockHeight() {
        let lastBlockHeight = 123
        let mockErc20Delegate = MockIEthereumKitDelegate()

        stub(mockDelegate) { mock in
            when(mock.onUpdateLastBlockHeight()).thenDoNothing()
        }
        stub(mockErc20Delegate) { mock in
            when(mock.onUpdateLastBlockHeight()).thenDoNothing()
        }
        stub(mockState) { mock in
            when(mock.erc20Delegates.get).thenReturn([mockErc20Delegate])
        }

        kit.onUpdate(lastBlockHeight: lastBlockHeight)

        verify(mockState).lastBlockHeight.set(equal(to: lastBlockHeight))
        verify(mockDelegate).onUpdateLastBlockHeight()
        verify(mockErc20Delegate).onUpdateLastBlockHeight()
    }

    func testOnUpdateBalance() {
        let balance: Decimal = 123.45

        stub(mockDelegate) { mock in
            when(mock.onUpdateBalance()).thenDoNothing()
        }

        kit.onUpdate(balance: balance)

        verify(mockState).balance.set(equal(to: balance))
        verify(mockDelegate).onUpdateBalance()
    }

    func testOnUpdateSyncState() {
        let syncState: EthereumKit.SyncState = .syncing

        stub(mockDelegate) { mock in
            when(mock.onUpdateSyncState()).thenDoNothing()
        }

        kit.onUpdate(syncState: syncState)

        verify(mockDelegate).onUpdateSyncState()
    }

    func testOnUpdateErc20Balance() {
        let balance: Decimal = 123.45
        let contractAddress = "contract_address"
        let mockErc20Delegate = MockIEthereumKitDelegate()

        stub(mockState) { mock in
            when(mock.set(balance: any(), contractAddress: any())).thenDoNothing()
            when(mock.delegate(contractAddress: contractAddress)).thenReturn(mockErc20Delegate)
        }
        stub(mockErc20Delegate) { mock in
            when(mock.onUpdateBalance()).thenDoNothing()
        }

        kit.onUpdateErc20(balance: balance, contractAddress: contractAddress)

        verify(mockState).set(balance: equal(to: balance), contractAddress: equal(to: contractAddress))
        verify(mockErc20Delegate).onUpdateBalance()
    }

    func testOnUpdateErc20SyncState() {
        let syncState: EthereumKit.SyncState = .syncing
        let contractAddress = "contract_address"
        let mockErc20Delegate = MockIEthereumKitDelegate()

        stub(mockState) { mock in
            when(mock.delegate(contractAddress: contractAddress)).thenReturn(mockErc20Delegate)
        }
        stub(mockErc20Delegate) { mock in
            when(mock.onUpdateSyncState()).thenDoNothing()
        }

        kit.onUpdateErc20(syncState: syncState, contractAddress: contractAddress)

        verify(mockErc20Delegate).onUpdateSyncState()
    }

}

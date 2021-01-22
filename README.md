# EthereumKit-iOS

EthereumKit-iOS is a native(Swift), secure, reactive and extensible Ethereum client toolkit for iOS platform. It can be used by ETH/Erc20 wallet or by dapp client for any kind of interactions with Ethereum blockchain. 

## Features

- Ethereum wallet support, including internal Ether transfer transactions
- Support for ERC20 token standard
- Uniswap DEX support
- Reactive-functional API
- Implementation of Ethereum's JSON-RPC client API over HTTP or WebSocket
- Support for Infura
- Support for Etherscan


### EthereumKit.swift
- Sync account state/balance
- Sync/Send/Receive Ethereum transactions 
- Internal transactions retrieved from Etherscan
- Reactive API for Smart Contracts (*Erc20Kit.swift* and *UniswapKit.swift* use *EthereumKit.swift* for interactions with the blockchain)
- Reactive API for wallet
- Restore with mnemonic phrase

### Erc20Kit.swift
- Sync balance
- Sync/Send/Receive Erc20 token transactions
- Allowance management
- Incoming Erc20 token transactions retrieved from Etherscan
- Reactive API for wallet

### UniswapKit.swift

Supports following settings:
- Price Impact
- Deadline
- Recipient
- Fee on Transfer

## Usage


### Initialization

First you need to initialize an EthereumKit.Kit instance

```swift
import EthereumKit

let ethereumKit = try! Kit.instance(
        words: ["word1", ... , "word12"],
        syncMode: .api,
        networkType: .ropsten,
        rpcApi: .infuraWebSocket(id: "", secret: ""),
        etherscanApiKey: "",
        walletId: "walletId",
        minLogLevel: .error
)
```

##### `syncMode` parameter

- `.api`: Uses RPC
- `.spv`: Ethereum light client. *Not supported currently*
- `.geth`: Geth client. *Not supported currenly*

##### `networkfkType` parameter

- `.mainNet`
- `.ropsten`
- `.kovan`

##### `rpcApi` parameter

- `.infuraWebSocket(id: "", secret: "")`: RPC over HTTP
- `.infura(id: "", secret: """)`: RPC over WebSocket

##### Additional parameters:
- `minLogLevel`: Can be configured for debug purposes if required.

### Starting and Stopping

*EthereumKit.Kit* instance requires to be started with `start` command

```swift
ethereumKit.start()
ethereumKit.stop()
```

### Getting wallet data

You can get account state, lastBlockHeight, syncState, transactionsSyncState and some others synchronously 

```swift
guard let state = ethereumKit.accountState else {
    return
}

state.balance    // 2937096768
state.nonce      // 10

ethereumKit.lastBlockHeight  // 10000000
```

You also can subscribe to Rx observables of those and some others

```swift
ethereumKit.accountStateObservable.subscribe(onNext: { state in print("balance: \(state.balance); nonce: \(state.nonce)") })
ethereumKit.lastBlockHeightObservable.subscribe(onNext: { height in print(height) })
ethereumKit.syncStateObservable.subscribe(onNext: { state in print(state) })
ethereumKit.transactionsSyncStateObservable.subscribe(onNext: { state in print(state) })

// Subscribe to all Ethereum transactions synced by the kit
ethereumKit.allTransactionsObservable.subscribe(onNext: { transactions in print(transactions.count) })

// Subscribe to Ether transactions
ethereumKit.etherTransactionsObservable.subscribe(onNext: { transactions in print(transactions.count) })
```

### Send Transaction

```swift
let decimalAmount: Decimal = 0.1
let amount = BigUInt(decimalAmount.roundedString(decimal: decimal))!
let address = Address(hex: "0x73eb56f175916bd17b97379c1fdb5af1b6a82c84")!

ethereumKit
        .sendSingle(address: address, value: amount, gasPrice: 50_000_000_000, gasLimit: 1_000_000_000_000)
        .subscribe(onSuccess: { transaction in 
            print(transaction.transaction.hash.hex)  // sendSingle returns FullTransaction object which contains transaction, receiptWithLogs and internalTransactions
        })
```

### Estimate Gas Limit

```swift
let decimalAmount: Decimal = 0.1
let amount = BigUInt(decimalAmount.roundedString(decimal: decimal))!
let address = Address(hex: "0x73eb56f175916bd17b97379c1fdb5af1b6a82c84")!

ethereumKit
        .estimateGas(to: address, amount: amount, gasPrice: 50_000_000_000)
        .subscribe(onSuccess: { gasLimit in 
            print(gasLimit)
        })
```

### Send Erc20 Transaction

```swift
import EthereumKit
import Erc20Kit

let decimalAmount: Decimal = 0.1
let amount = BigUInt(decimalAmount.roundedString(decimal: decimal))!
let address = Address(hex: "0x73eb56f175916bd17b97379c1fdb5af1b6a82c84")!

let erc20Kit = Erc20Kit.Kit.instance(ethereumKit: ethereumKit, contractAddress: "contract address of token")
let transactionData = erc20Kit.transferTransactionData(to: address, value: amount)

ethereumKit
        .sendSingle(transactionData: transactionData, gasPrice: 50_000_000_000, gasLimit: 1_000_000_000_000)
        .subscribe(onSuccess: { [weak self] _ in})
```

### Send Uniswap swap transaction

```swift
import EthereumKit
import UniswapKit
import Erc20Kit

let uniswapKit = UniswapKit.Kit.instance(ethereumKit: ethereumKit)

let tokenIn = uniswapKit.etherToken
let tokenOut = uniswapKit.token(try! Address(hex: "0xad6d458402f60fd3bd25163575031acdce07538d"), decimal: 18)
let amount: Decimal = 0.1

uniswapKit
        .swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
        .flatMap { swapData in
            let tradeData = try! uniswapKit.bestTradeExactIn(swapData: swapData, amountIn: amount)
            let transactionData = try! uniswapKit.transactionData(tradeData: tradeData)
            
            return ethereumKit.sendSingle(transactionData: transactionData, gasPrice: 50_000_000_000, gasLimit: 1_000_000_000_000)
        }
        .subscribe(onSuccess: { [weak self] _ in})
```

## Extending

### Add transaction syncer

Some smart contracts store some information concerning your address, which you can't retrieve in a standard way over RPC. If you have an external API to get them from, you can create a custom syncer and add it to EthereumKit. It will sync all the transactions your syncer gives. 

[Erc20TransactionSyncer](https://github.com/horizontalsystems/ethereum-kit-ios/blob/master/Erc20Kit/Classes/Core/Erc20TransactionSyncer.swift) is a good example of this. It gets token transfer transactions from Etherscan and feeds EthereumKit syncer with them. It is added to EthereumKit as following:
```swift
let transactionSyncer = Erc20TransactionSyncer(...)
ethereumKit.add(syncer: transactionSyncer)
```

### Smart contract call

In order to make a call to any smart contract, you can use `ethereumKit.sendSingle(transactionData:,gasPrice:,gasLimit:)` method. You need to create an instance of `TransactionData` object. Currently, we don't have an ABI or source code parser. Please, look in Erc20Kit.swift and UniswapKit.swift to see how `TransactionData` object is formed. 


## Prerequisites

* Xcode 10.0+
* Swift 5+
* iOS 11+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.5.0+ is required to build EthereumKit.

To integrate EthereumKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
  pod 'EthereumKit.swift'
  pod 'Erc20.swift'
  pod 'UniswapKit.swift'
end
```

Then, run the following command:
```bash
$ pod install
```


## Example Project

All features of the library are used in example project. It can be referred as a starting point for usage of the library.

* [Example Project](https://github.com/horizontalsystems/ethereum-kit-ios/tree/master/Example)

## Dependencies

* [HSHDWalletKit](https://github.com/horizontalsystems/hd-wallet-kit-ios) - HD Wallet related features, mnemonic phrase generation.
* [OpenSslKit.swift](https://github.com/horizontalsystems/open-ssl-kit-ios) - Crypto functions required for working with blockchain.
* [Secp256k1Kit.swift](https://github.com/horizontalsystems/secp256k1-kit-ios) - Crypto functions required for working with blockchain. 
* [HsToolKit.swift](https://github.com/horizontalsystems/hs-tool-kit-ios) - Helpers library from HorizontalSystems
* RxSwift
* BigInt
* GRDB.swift
* Starscream

## License

The `EthereumKit-iOS` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/ethereum-kit-ios/blob/master/LICENSE).


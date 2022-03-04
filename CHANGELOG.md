# Change Log
All notable changes to this project will be documented in this file.

## Current Version

* add `Arbitrum One` chain support
* add `Optimism` chain support

## 0.16.0

* add support polygon chain with hold/send/swap
* add support EIP1599
* Refactor the way chains are handled [ **non-back-compatible api change** ]
  * replace old `NetworkType` enum with new `Chain` entity 
  * refactor `SyncSource` into to separate enums: `RpcSource` and `TransactionSource`

## 0.15.1

* Bugfixes and enhancements

## 0.15.0

* `EthereumKit`
  * Add ability to sign message via EIP712
* Refactor transactions decorations [ **non-back-compatible api change** ]

## 0.14.0

* Synchronization refactoring [ **non-back-compatible api change** ]
* Use iOS native URLSessionWebSocketTask instead of Starscream
* Increase minimum iOS version to 13.0 [ **non-back-compatible api change** ]
* Accept seed data instead of words array when getting instance of `EthereumKit`, address or private key [ **non-back-compatible api change** ]

## 0.13.0

* `EthereumKit`
  * Add support to BSC. Kit initialization method changed [ **non-back-compatible api change** ]
  * Update `Etherscan` testnet urls

* `UniswapKit`
  * Add support to PancakeSwap
  

## 0.12.0
  
* `EthereumKit`
  * make `WebSocketState` errors public
  * add rpc error case
  * Transaction sync refactoring. [ **non-back-compatible api change** ]
  * Add EthereumKit.Kit#address(words:networkType:) method to get an ethereum address from account
  
* `Erc20Kit`
  * Transaction sync refactoring. [ **non-back-compatible api change** ]
 

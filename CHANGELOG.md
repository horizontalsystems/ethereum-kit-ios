# Change Log
All notable changes to this project will be documented in this file.

## Current Version

* Use iOS native URLSessionWebSocketTask instead of Starscream
* Increase minimum iOS version to 13.0 [ **non-back-compatible api change** ]

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
 

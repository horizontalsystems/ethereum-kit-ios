platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'HSEthereumKit'

project 'HSEthereumKitDemo/HSEthereumKitDemo'
project 'HSEthereumKit/HSEthereumKit'

def common_pods
  pod 'RxSwift', '~> 4.0'

  pod 'HSCryptoKit', :git => 'https://github.com/horizontalsystems/crypto-kit-ios.git', :branch => 'ethereum_light_client_crypto'
  pod 'HSHDWalletKit', :git => 'https://github.com/horizontalsystems/hd-wallet-kit-ios.git', :branch => 'ethereum_light_client'

  pod 'GRDB.swift'

  pod 'Alamofire', '~> 4.8.0'
end

target :HSEthereumKitDemo do
  project 'HSEthereumKitDemo/HSEthereumKitDemo'
  common_pods
end

target :HSEthereumKit do
  project 'HSEthereumKit/HSEthereumKit'
  common_pods
end

target :HSEthereumKitTests do
  project 'HSEthereumKit/HSEthereumKit'
  pod "Cuckoo", '~> 0.12.0'
end
platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'EthereumKit'

project 'EthereumKit/EthereumKit'
project 'Erc20Kit/Erc20Kit'
project 'EthereumKitDemo/EthereumKitDemo'

def common_pods
  pod 'RxSwift', '~> 4.0'

  pod 'HSCryptoKit', git: 'https://github.com/horizontalsystems/crypto-kit-ios'
  pod 'HSHDWalletKit', '~> 1.0'

  pod 'GRDB.swift', '~> 3.0'

  pod 'Alamofire', '~> 4.0'

  pod 'BigInt', '~> 4.0'
end

def test_pods
  pod 'Cuckoo'
  pod 'Quick'
  pod 'Nimble'
end

target :EthereumKit do
  project 'EthereumKit/EthereumKit'
  common_pods
end

target :Erc20Kit do
  project 'Erc20Kit/Erc20Kit'
  common_pods
end

target :EthereumKitDemo do
  project 'EthereumKitDemo/EthereumKitDemo'
  common_pods
end

target :EthereumKitTests do
  project 'EthereumKit/EthereumKit'
  test_pods
end

target :Erc20KitTests do
  project 'Erc20Kit/Erc20Kit'
  test_pods
end

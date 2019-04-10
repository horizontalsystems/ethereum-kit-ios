platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'HSEthereumKit'

project 'HSEthereumKitDemo/HSEthereumKitDemo'
project 'HSEthereumKit/HSEthereumKit'
project 'HSErc20Kit/HSErc20Kit'

def common_pods
  pod 'RxSwift', '~> 4.0'

  pod 'HSCryptoKit', git: 'https://github.com/horizontalsystems/crypto-kit-ios'
  pod 'HSHDWalletKit', '~> 1.0.4'

  pod 'GRDB.swift', '~> 3.6.2'

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

target :HSErc20Kit do
  project 'HSErc20Kit/HSErc20Kit'
  common_pods
end

target :HSEthereumKitTests do
  project 'HSEthereumKit/HSEthereumKit'
  pod 'Cuckoo'
  pod 'Quick'
  pod 'Nimble'
end

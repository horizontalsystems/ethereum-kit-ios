platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'HSEthereumKit'

project 'HSEthereumKitDemo/HSEthereumKitDemo'
project 'HSEthereumKit/HSEthereumKit'

def kit_pods
  pod 'HSCryptoKit', '~> 1.1.0'

  pod 'RxSwift', '~> 4.3.1'

  pod 'RealmSwift', '~> 3.11.1'
  pod "RxRealm", '~> 0.7.5'

  pod 'Alamofire', '~> 4.8.0'
end

target :HSEthereumKitDemo do
 project 'HSEthereumKitDemo/HSEthereumKitDemo'
 kit_pods
end

target :HSEthereumKit do
  project 'HSEthereumKit/HSEthereumKit'
  kit_pods
end

target :HSEthereumKitTests do
  project 'HSEthereumKit/HSEthereumKit'

  kit_pods
  pod "Cuckoo", '~> 0.12.0'
end
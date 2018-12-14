platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'HSEthereumKit'

project 'HSEthereumKitDemo/HSEthereumKitDemo'
project 'HSEthereumKit/HSEthereumKit'

def kit_pods
  pod 'HSCryptoKit'
  pod 'CryptoSwift'

  pod 'RxSwift'

  pod 'RealmSwift'
  pod "RxRealm"

  pod 'Alamofire'
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
  pod "Cuckoo"
end

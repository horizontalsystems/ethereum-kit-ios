platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'Example'

project 'Example/Example'
project 'HSEthereumKit/HSEthereumKit'

def kit_pods
  pod 'RxSwift'

  pod 'RealmSwift'
  pod "RxRealm"

  pod "CryptoEthereumSwift", git: "https://github.com/horizontalsystems/CryptoEthereumSwift"
  pod "CryptoSwift"
end

target :Example do
 project 'Example/Example'
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

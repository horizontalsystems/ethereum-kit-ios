Pod::Spec.new do |spec|
  spec.name = 'HSEthereumKit'
  spec.version = '0.1.0'
  spec.summary = 'Ethereum wallet library for Swift'
  spec.description = <<-DESC
                       Ethereum implements Ethereum protocol in Swift. Uses EthereumKit libruary.
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/ethereum-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'grouvilimited@gmail.com' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git', tag: "v#{spec.version}" }
  spec.source_files = 'HSEthereumKit/HSEthereumKit/**/*.{h,m,swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '4.0'

  spec.pod_target_xcconfig = { 'SWIFT_WHOLE_MODULE_OPTIMIZATION' => 'YES',
                               'APPLICATION_EXTENSION_API_ONLY' => 'YES' }

  spec.dependency 'Cuckoo'
  spec.dependency 'CryptoEthereumSwift'
  spec.dependency 'RxSwift'
  spec.dependency 'RealmSwift'
  spec.dependency 'RxRealm'
end
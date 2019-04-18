Pod::Spec.new do |spec|
  spec.name = 'EthereumKit.swift'
  spec.module_name = 'EthereumKit'
  spec.version = '0.5'
  spec.summary = 'Ethereum wallet library for Swift'
  spec.description = <<-DESC
                       HSEthereumKit implements Ethereum protocol in Swift. Uses EthereumKit library.
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/ethereum-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git', tag: "ethereum-kit-#{spec.version}" }
  spec.source_files = 'EthereumKit/EthereumKit/**/*.{h,m,swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '4.2'

  spec.dependency 'HSCryptoKit', '~> 1.0'
  spec.dependency 'HSHDWalletKit', '~> 1.0'
  spec.dependency 'RxSwift', '~> 4.0'
  spec.dependency 'Alamofire', '~> 4.0'
  spec.dependency 'GRDB.swift', '~> 3.0'
end

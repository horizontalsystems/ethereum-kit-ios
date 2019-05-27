Pod::Spec.new do |spec|
  spec.name = 'EthereumKit.swift'
  spec.module_name = 'EthereumKit'
  spec.version = '0.6.1'
  spec.summary = 'Ethereum wallet library for Swift'
  spec.description = <<-DESC
                       EthereumKit.swift implements Ethereum protocol in Swift.
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/ethereum-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git', tag: "#{spec.version}" }
  spec.source_files = 'EthereumKit/EthereumKit/**/*.{h,m,swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5'

  spec.dependency 'HSCryptoKit', '~> 1.4'
  spec.dependency 'HSHDWalletKit', '~> 1.1'
  spec.dependency 'RxSwift', '~> 5.0'
  spec.dependency 'Alamofire', '~> 4.0'
  spec.dependency 'GRDB.swift', '~> 4.0'
  spec.dependency 'BigInt', '~> 4.0'
end

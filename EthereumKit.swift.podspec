Pod::Spec.new do |s|
  s.name             = 'EthereumKit.swift'
  s.module_name      = 'EthereumKit'
  s.version          = '0.8'
  s.summary          = 'Ethereum wallet library for Swift.'

  s.description      = <<-DESC
EthereumKit.swift implements Ethereum protocol in Swift.
                       DESC

  s.homepage         = 'https://github.com/horizontalsystems/ethereum-kit-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  s.source           = { git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git', tag: "#{s.version}" }
  s.social_media_url = 'http://horizontalsystems.io/'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5'

  s.source_files = 'EthereumKit/Classes/**/*'

  s.requires_arc = true

  s.dependency 'OpenSslKit.swift', '~> 1.0'
  s.dependency 'Secp256k1Kit.swift', '~> 1.0'
  s.dependency 'HSHDWalletKit', '~> 1.3'

  s.dependency 'Alamofire', '~> 4.0'
  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'BigInt', '~> 4.0'
  s.dependency 'GRDB.swift', '~> 4.0'
  s.dependency 'BlueSocket', '~> 1.0'
end

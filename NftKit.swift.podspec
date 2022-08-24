Pod::Spec.new do |s|
  s.name             = 'NftKit.swift'
  s.module_name      = 'NftKit'
  s.version          = '0.16.0'
  s.summary          = 'EIP-721 and EIP-1155 tokens library for Swift.'

  s.homepage         = 'https://github.com/horizontalsystems/ethereum-kit-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  s.source           = { git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git', tag: "#{s.version}" }
  s.social_media_url = 'http://horizontalsystems.io/'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5'

  s.source_files = 'NftKit/Classes/**/*'

  s.requires_arc = true

  s.dependency 'EthereumKit.swift', '~> 0.16'
  s.dependency 'OpenSslKit.swift', '~> 1.0'
  s.dependency 'Secp256k1Kit.swift', '~> 1.0'
  s.dependency 'UIExtensions.swift', '~> 1.1.0'

  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'BigInt', '~> 5.0'
  s.dependency 'GRDB.swift', '~> 5.0'
end

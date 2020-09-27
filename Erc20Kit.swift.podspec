Pod::Spec.new do |s|
  s.name             = 'Erc20Kit.swift'
  s.module_name      = 'Erc20Kit'
  s.version          = '0.11.0'
  s.summary          = 'Erc20 token library for Swift.'

  s.homepage         = 'https://github.com/horizontalsystems/ethereum-kit-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  s.source           = { git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git', tag: "#{s.version}" }
  s.social_media_url = 'http://horizontalsystems.io/'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5'

  s.source_files = 'Erc20Kit/Classes/**/*'

  s.requires_arc = true

  s.dependency 'EthereumKit.swift', '~> 0.11'
  s.dependency 'OpenSslKit.swift', '~> 1.0'
  s.dependency 'Secp256k1Kit.swift', '~> 1.0'
  s.dependency 'UIExtensions.swift', '~> 1.1.0'

  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'BigInt', '~> 5.0'
  s.dependency 'GRDB.swift', '~> 4.0'
end

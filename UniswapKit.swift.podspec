Pod::Spec.new do |s|
  s.name             = 'UniswapKit.swift'
  s.module_name      = 'UniswapKit'
  s.version          = '0.9.2'
  s.summary          = 'Uniswap exchange integration for Swift.'

  s.homepage         = 'https://github.com/horizontalsystems/ethereum-kit-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  s.source           = { git: 'https://github.com/horizontalsystems/ethereum-kit-ios.git', tag: "uniswap-#{s.version}" }
  s.social_media_url = 'http://horizontalsystems.io/'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5'

  s.source_files = 'UniswapKit/Classes/**/*'

  s.requires_arc = true

  s.dependency 'EthereumKit.swift', '~> 0.11'
  s.dependency 'OpenSslKit.swift', '~> 1.0'
  s.dependency 'Secp256k1Kit.swift', '~> 1.0'

  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'BigInt', '~> 5.0'
end

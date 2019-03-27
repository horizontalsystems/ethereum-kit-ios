import HSCryptoKit
import HSHDWalletKit

/// Wallet handles all the logic necessary for storing keys
public final class Wallet {

    /// Network which this wallet is connecting to
    /// Basiclly Mainnet or Ropsten
    private let network: Network
    
    /// Private key which this wallet mainly use.
    /// This is either provided by user or generated from HD wallet.
    /// for HD wallet, path is m/44'/coin_type'/0'/0
    private let key: HDPrivateKey
    
    public init(seed: Data, network: Network, debugPrints: Bool) throws {
        self.network = network
        let wallet = HDWallet(seed: seed, coinType: network.coinType, xPrivKey: network.privateKeyPrefix.bigEndian, xPubKey: network.publicKeyPrefix.bigEndian)

        // m/44'/coin_type'/0'/external
        key = try wallet.privateKey(account: 0, index: 0, chain: .external)
    }

}

// MARK :- Keys

extension Wallet {

    /// Generates address from main private key.
    ///
    /// - Returns: Address in string format
    public func address() -> String {
        return Address(data: CryptoKit.sha3(publicKey().dropFirst()).suffix(20)).string
    }

    /// Reveal public key of this wallet in data format
    ///
    /// - Returns: Public key in data format
    public func publicKey() -> Data {
        return key.publicKey(compressed: false).raw
    }
}

// MARK: - Sign Transaction

extension Wallet {
    
    /// Sign signs rlp encoding hash of specified raw transaction
    ///
    /// - Parameter rawTransaction: raw transaction to hash
    /// - Returns: signiture in hex format
    /// - Throws: EthereumKitError.failedToEncode when failed to encode
//    public func sign(rawTransaction: RawTransaction) throws -> String {
//        let signer = EIP155Signer(chainID: network.chainID)
//        let rawData = try signer.sign(rawTransaction, privateKey: key.raw)
//        let hash = rawData.toHexString().addHexPrefix()
//
//        return hash
//    }
}

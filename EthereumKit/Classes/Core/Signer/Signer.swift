import RxSwift
import HdWalletKit
import BigInt
import OpenSslKit
import Secp256k1Kit
import HsToolKit

public class Signer {
    private let transactionBuilder: TransactionBuilder
    private let transactionSigner: TransactionSigner
    private let ethSigner: EthSigner

    init(transactionBuilder: TransactionBuilder, transactionSigner: TransactionSigner, ethSigner: EthSigner) {
        self.transactionBuilder = transactionBuilder
        self.transactionSigner = transactionSigner
        self.ethSigner = ethSigner
    }

    public func signature(rawTransaction: RawTransaction) throws -> Signature {
        try transactionSigner.signature(rawTransaction: rawTransaction)
    }

    public func signedTransaction(address: Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: GasPrice, gasLimit: Int, nonce: Int) throws -> Data {
        let rawTransaction = RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: address, value: value, data: transactionInput, nonce: nonce)
        let signature = try transactionSigner.signature(rawTransaction: rawTransaction)
        return transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)
    }

    public func signed(message: Data) throws -> Data {
        try ethSigner.sign(message: message)
    }

    public func parseTypedData(rawJson: Data) throws -> EIP712TypedData {
        try ethSigner.parseTypedData(rawJson: rawJson)
    }

    public func signTypedData(message: Data) throws -> Data {
        try ethSigner.signTypedData(message: message)
    }

}

extension Signer {

    public static func instance(seed: Data, chain: Chain) throws -> Signer {
        let privKey = try privateKey(seed: seed, chain: chain)
        let address = ethereumAddress(privateKey: privKey)

        let transactionSigner = TransactionSigner(chain: chain, privateKey: privKey.raw)
        let transactionBuilder = TransactionBuilder(chain: chain, address: address)
        let ethSigner = EthSigner(privateKey: privKey.raw, cryptoUtils: CryptoUtils.shared)

        return Signer(transactionBuilder: transactionBuilder, transactionSigner: transactionSigner, ethSigner: ethSigner)
    }

    public static func address(seed: Data, chain: Chain) throws -> Address {
        let privKey = try privateKey(seed: seed, chain: chain)

        return ethereumAddress(privateKey: privKey)
    }

    public static func privateKey(seed: Data, chain: Chain) throws -> HDPrivateKey {
        let wallet = hdWallet(seed: seed, chain: chain)
        return try wallet.privateKey(account: 0, index: 0, chain: .external)
    }

    private static func hdWallet(seed: Data, chain: Chain) -> HDWallet {
        HDWallet(seed: seed, coinType: chain.coinType, xPrivKey: 0, xPubKey: 0)
    }

    private static func ethereumAddress(privateKey: HDPrivateKey) -> Address {
        let publicKey = Data(Secp256k1Kit.Kit.createPublicKey(fromPrivateKeyData: privateKey.raw, compressed: false).dropFirst())

        return Address(raw: Data(CryptoUtils.shared.sha3(publicKey).suffix(20)))
    }

}

extension Signer {

    public enum SendError: Error {
        case weakReferenceError
    }

}

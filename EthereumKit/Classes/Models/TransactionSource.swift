public struct TransactionSource {
    public let name: String
    public let type: SourceType

    public func transactionUrl(hash: String) -> String {
        switch type {
        case .etherscan(let baseUrl, _):
            return "\(baseUrl)/tx/\(hash)"
        }
    }

    public enum SourceType {
        case etherscan(baseUrl: String, apiKey: String)
    }
}

extension TransactionSource {

    private static func etherscan(subdomain: String, apiKey: String) -> TransactionSource {
        TransactionSource(
                name: "etherscan.io",
                type: .etherscan(baseUrl: "https://\(subdomain).etherscan.io", apiKey: apiKey)
        )
    }

    public static func ethereumEtherscan(apiKey: String) -> TransactionSource {
        etherscan(subdomain: "api", apiKey: apiKey)
    }

    public static func ropstenEtherscan(apiKey: String) -> TransactionSource {
        etherscan(subdomain: "api-ropsten", apiKey: apiKey)
    }

    public static func kovanEtherscan(apiKey: String) -> TransactionSource {
        etherscan(subdomain: "api-kovan", apiKey: apiKey)
    }

    public static func rinkebyEtherscan(apiKey: String) -> TransactionSource {
        etherscan(subdomain: "api-rinkeby", apiKey: apiKey)
    }

    public static func goerliEtherscan(apiKey: String) -> TransactionSource {
        etherscan(subdomain: "api-goerli", apiKey: apiKey)
    }

    public static func bscscan(apiKey: String) -> TransactionSource {
        TransactionSource(
                name: "bscscan.com",
                type: .etherscan(baseUrl: "https://api.bscscan.com", apiKey: apiKey)
        )
    }

}

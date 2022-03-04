public struct TransactionSource {
    public let name: String
    public let type: SourceType

    public init(name: String, type: SourceType) {
        self.name = name
        self.type = type
    }

    public func transactionUrl(hash: String) -> String {
        switch type {
        case .etherscan(_, let txBaseUrl, _):
            return "\(txBaseUrl)/tx/\(hash)"
        }
    }

    public enum SourceType {
        case etherscan(apiBaseUrl: String, txBaseUrl: String, apiKey: String)
    }
}

extension TransactionSource {

    private static func etherscan(apiSubdomain: String, txSubdomain: String?, apiKey: String) -> TransactionSource {
        TransactionSource(
                name: "etherscan.io",
                type: .etherscan(apiBaseUrl: "https://\(apiSubdomain).etherscan.io", txBaseUrl: "https://\(txSubdomain.map { "\($0)." } ?? "")etherscan.io", apiKey: apiKey)
        )
    }

    public static func ethereumEtherscan(apiKey: String) -> TransactionSource {
        etherscan(apiSubdomain: "api", txSubdomain: nil, apiKey: apiKey)
    }

    public static func ropstenEtherscan(apiKey: String) -> TransactionSource {
        etherscan(apiSubdomain: "api-ropsten", txSubdomain: "ropsten", apiKey: apiKey)
    }

    public static func kovanEtherscan(apiKey: String) -> TransactionSource {
        etherscan(apiSubdomain: "api-kovan", txSubdomain: "kovan", apiKey: apiKey)
    }

    public static func rinkebyEtherscan(apiKey: String) -> TransactionSource {
        etherscan(apiSubdomain: "api-rinkeby", txSubdomain: "rinkeby", apiKey: apiKey)
    }

    public static func goerliEtherscan(apiKey: String) -> TransactionSource {
        etherscan(apiSubdomain: "api-goerli", txSubdomain: "goerli", apiKey: apiKey)
    }

    public static func bscscan(apiKey: String) -> TransactionSource {
        TransactionSource(
                name: "bscscan.com",
                type: .etherscan(apiBaseUrl: "https://api.bscscan.com", txBaseUrl: "https://bscscan.com", apiKey: apiKey)
        )
    }

    public static func polygonscan(apiKey: String) -> TransactionSource {
        TransactionSource(
                name: "polygonscan.com",
                type: .etherscan(apiBaseUrl: "https://api.polygonscan.com", txBaseUrl: "https://polygonscan.com", apiKey: apiKey)
        )
    }

    public static func optimisticEtherscan(apiKey: String) -> TransactionSource {
        TransactionSource(
                name: "optimistic.etherscan.io",
                type: .etherscan(apiBaseUrl: "https://api-optimistic.etherscan.io", txBaseUrl: "https://optimistic.etherscan.io", apiKey: apiKey)
        )
    }

    public static func arbiscan(apiKey: String) -> TransactionSource {
        TransactionSource(
                name: "arbiscan.io",
                type: .etherscan(apiBaseUrl: "https://api.arbiscan.io", txBaseUrl: "https://arbiscan.io", apiKey: apiKey)
        )
    }

}

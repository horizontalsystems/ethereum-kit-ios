import Foundation

public enum RpcSource {
    case http(urls: [URL], auth: String?)
    case webSocket(url: URL, auth: String?)
}

extension RpcSource {

    private static func infuraHttp(subdomain: String, projectId: String, projectSecret: String? = nil) -> RpcSource {
        .http(urls: [URL(string: "https://\(subdomain).infura.io/v3/\(projectId)")!], auth: projectSecret)
    }

    private static func infuraWebsocket(subdomain: String, projectId: String, projectSecret: String? = nil) -> RpcSource {
        .webSocket(url: URL(string: "wss://\(subdomain).infura.io/ws/v3/\(projectId)")!, auth: projectSecret)
    }

    public static func ethereumInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "mainnet", projectId: projectId, projectSecret: projectSecret)
    }

    public static func ropstenInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "ropsten", projectId: projectId, projectSecret: projectSecret)
    }

    public static func kovanInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "kovan", projectId: projectId, projectSecret: projectSecret)
    }

    public static func rinkebyInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "rinkeby", projectId: projectId, projectSecret: projectSecret)
    }

    public static func goerliInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "goerli", projectId: projectId, projectSecret: projectSecret)
    }

    public static func ethereumInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "mainnet", projectId: projectId, projectSecret: projectSecret)
    }

    public static func ropstenInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "ropsten", projectId: projectId, projectSecret: projectSecret)
    }

    public static func kovanInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "kovan", projectId: projectId, projectSecret: projectSecret)
    }

    public static func rinkebyInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "rinkeby", projectId: projectId, projectSecret: projectSecret)
    }

    public static func goerliInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "goerli", projectId: projectId, projectSecret: projectSecret)
    }

    public static func bscRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://bscrpc.com")!], auth: nil)
    }

    public static func binanceSmartChainHttp() -> RpcSource {
        .http(urls: [
            URL(string: "https://bsc-dataseed.binance.org")!,
            URL(string: "https://bsc-dataseed1.binance.org")!,
            URL(string: "https://bsc-dataseed2.binance.org")!,
            URL(string: "https://bsc-dataseed3.binance.org")!,
            URL(string: "https://bsc-dataseed4.binance.org")!
        ], auth: nil)
    }

    public static func binanceSmartChainWebSocket() -> RpcSource {
        .webSocket(url: URL(string: "wss://bsc-ws-node.nariox.org:443")!, auth: nil)
    }

    public static func polygonRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://polygon-rpc.com")!], auth: nil)
    }

    public static func optimismRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://mainnet.optimism.io")!], auth: nil)
    }

    public static func arbitrumOneRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://arb1.arbitrum.io/rpc")!], auth: nil)
    }

}

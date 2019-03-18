public final class IPFS {

    public struct GetGasPrices: RequestType {
        public typealias Response = GasPrice

        public struct Configuration {
            public let baseURL: URL

            public init(baseURL: URL) {
                self.baseURL = baseURL
            }
        }

        public let configuration: Configuration

        public var baseURL: URL {
            return configuration.baseURL
        }

        public var method: Method {
            return .get
        }

        public var path: String {
            return "blockchain/estimatefee/index.json"
        }

        public var parameters: Any? {
            return nil
        }
    }

}

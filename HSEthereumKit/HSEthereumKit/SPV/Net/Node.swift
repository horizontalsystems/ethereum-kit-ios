import Foundation

class Node {

    let id: Data
    let host: String
    let port: Int
    let discoveryPort: Int

    init(id: Data, host: String, port: Int, discoveryPort: Int) {
        self.id = id
        self.host = host
        self.port = port
        self.discoveryPort = discoveryPort
    }

}

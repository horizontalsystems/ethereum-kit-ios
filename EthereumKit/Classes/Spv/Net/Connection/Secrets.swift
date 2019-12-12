import Foundation
import OpenSslKit

class Secrets {

    let aes: Data
    let mac: Data
    let token: Data
    let egressMac: KeccakDigest
    let ingressMac: KeccakDigest

    init(aes: Data, mac: Data, token: Data, egressMac: KeccakDigest, ingressMac: KeccakDigest) {
        self.aes = aes
        self.mac = mac
        self.token = token
        self.egressMac = egressMac
        self.ingressMac = ingressMac
    }

}

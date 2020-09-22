import EthereumKit
import BigInt

class GetReservesMethod: ContractMethod {
    override var methodSignature: String { "getReserves()" }
    override var arguments: [Any] { [] }
}

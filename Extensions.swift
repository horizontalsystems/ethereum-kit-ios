import EthereumKit
import BigInt

extension TransactionLog {

    func uniswapEvent() -> UniswapLogEvent? {
        guard topics.count == 3, data.count == 128 else {
            return nil
        }

        let signature = topics[0]
        let sender = Address(raw: topics[1])
        let to = Address(raw: topics[2])

        if signature == UniswapLogEvent.swapSignature {
            let amount0In = BigUInt(Data(data[0..<32]))
            let amount1In = BigUInt(Data(data[32..<64]))
            let amount0Out = BigUInt(Data(data[64..<96]))
            let amount1Out = BigUInt(Data(data[96..<128]))

            return .swap(sender: sender, amount0In: amount0In, amount1In: amount1In, amount0Out: amount0Out, amount1Out: amount1Out, to: to)
        }

        return nil
    }

}

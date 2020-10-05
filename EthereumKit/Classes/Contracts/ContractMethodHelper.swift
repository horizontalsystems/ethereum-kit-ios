import OpenSslKit
import BigInt

public class ContractMethodHelper {

    public static func encodedABI(methodId: Data, arguments: [Any]) -> Data {
        var data = methodId
        var arraysData = Data()

        for argument in arguments {
            switch argument {
            case let argument as BigUInt:
                data += pad(data: argument.serialize())
            case let argument as Address:
                data += pad(data: argument.raw)
            case let argument as [Address]:
                data += pad(data: BigUInt(arguments.count * 32 + arraysData.count).serialize())
                arraysData += encode(array: argument.map { $0.raw })
            default:
                ()
            }
        }

        return data + arraysData
    }

    public static func methodId(signature: String) -> Data {
        OpenSslKit.Kit.sha3(signature.data(using: .ascii)!)[0...3]
    }

//    private var signature: Data {
//        let argumentTypes = arguments.map { $0.type }.joined(separator: ",")
//        let structure = "\(name)(\(argumentTypes))"
//        return OpenSslKit.Kit.sha3(structure.data(using: .ascii)!)[0...3]
//    }

    private static func encode(array: [Data]) -> Data {
        var data = pad(data: BigUInt(array.count).serialize())

        for item in array {
            data += pad(data: item)
        }

        return data
    }

    private static func pad(data: Data) -> Data {
        Data(repeating: 0, count: (max(0, 32 - data.count))) + data
    }

}

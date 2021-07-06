import OpenSslKit
import BigInt
import Foundation

public class ContractMethodHelper {

    public struct StructParameter {
        let arguments: [Any]

        public init(_ arguments: [Any]) {
            self.arguments = arguments
        }
    }

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
            case is Data:
                data += pad(data: BigUInt(arguments.count * 32 + arraysData.count).serialize())
                arraysData += pad(data: BigUInt(data.count).serialize()) + data
            default:
                ()
            }
        }

        return data + arraysData
    }

    public class func decodeABI(inputArguments: Data, argumentTypes: [Any]) -> [Any] {
        var position = 0
        var parsedArguments = [Any]()

        for type in argumentTypes {
            switch type {
            case is BigUInt.Type:
                let data = Data(inputArguments[position..<position + 32])
                parsedArguments.append(BigUInt(data))
                position += 32

            case is Address.Type:
                let data = Data(inputArguments[position..<position + 32])
                parsedArguments.append(Address(raw: data))
                position += 32

            case is [Address].Type:
                let arrayPosition = parseInt(data: inputArguments[position..<position + 32])
                let array: [Address] = parseAddresses(startPosition: arrayPosition, inputArguments: inputArguments)
                parsedArguments.append(array)
                position += 32

            case is Data.Type:
                let dataPosition = parseInt(data: inputArguments[position..<position + 32])
                let data: Data = parseData(startPosition: dataPosition, inputArguments: inputArguments)
                parsedArguments.append(data)
                position += 32

            case is [Data].Type:
                let dataPosition = parseInt(data: inputArguments[position..<position + 32])
                let data: [Data] = parseDataArray(startPosition: dataPosition, inputArguments: inputArguments)
                parsedArguments.append(data)
                position += 32

            case let object as StructParameter:
                let argumentsPosition = parseInt(data: inputArguments[position..<position + 32])
                let data: [Any] = decodeABI(inputArguments: Data(inputArguments[argumentsPosition..<inputArguments.count]), argumentTypes: object.arguments)
                parsedArguments.append(data)
                position += 32

            default: ()
            }
        }

        return parsedArguments
    }

    public static func methodId(signature: String) -> Data {
        OpenSslKit.Kit.sha3(signature.data(using: .ascii)!)[0...3]
    }

    private class func parseInt(data: Data) -> Int {
        Data(data.reversed()).to(type: Int.self)
    }

    private class func parseAddresses(startPosition: Int, inputArguments: Data) -> [Address] {
        let arrayStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition..<arrayStartPosition])
        var addresses = [Address]()

        for i in 0..<size {
            let addressData = Data(inputArguments[(arrayStartPosition + 32 * i)..<(arrayStartPosition + 32 * (i + 1))])
            addresses.append(Address(raw: addressData))
        }

        return addresses
    }

    private class func parseData(startPosition: Int, inputArguments: Data) -> Data {
        let dataStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition..<dataStartPosition])
        return Data(inputArguments[dataStartPosition..<(dataStartPosition + size)])
    }

    private class func parseDataArray(startPosition: Int, inputArguments: Data) -> [Data] {
        let arrayStartPosition = startPosition + 32
        let size = parseInt(data: inputArguments[startPosition..<arrayStartPosition])
        var dataArray = [Data]()

        for i in 0..<size {
            dataArray.append(Data(inputArguments[(arrayStartPosition + 32 * i)..<(arrayStartPosition + 32 * (i + 1))]))
        }

        return dataArray
    }

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

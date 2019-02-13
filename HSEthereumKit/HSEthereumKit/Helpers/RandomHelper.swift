import Foundation

func randomBytes(length: Int) -> Data {
    var bytes = Data(count: length)
    let _ = bytes.withUnsafeMutableBytes {
        (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
        SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
    }

    return bytes
}


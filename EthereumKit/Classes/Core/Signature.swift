import BigInt

public class Signature {
    let v: Int
    let r: BigUInt
    let s: BigUInt

    init(v: Int, r: BigUInt, s: BigUInt) {
        self.v = v
        self.r = r
        self.s = s
    }

}

import RxSwift

public typealias Signal = PublishSubject<Void>

public extension PublishSubject where Element == Void {

    func notify() {
        self.onNext(())
    }

}

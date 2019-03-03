//
//  ObservableHelpers.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/19.
//

import RxSwift
import RxCocoa
import RxSwiftExt


func forkSignal<T>(
        observable: Observable<Event<T>>
    ) -> (
        Observable<T>,
        Observable<Error>,
        Observable<Void>
    ) {
        let next = observable.filterMap { (event) -> FilterMap<T> in
            if case let .next(val) = event {
                return .map(val)
            }
            return .ignore
        }
        let err = observable.filterMap { (event) -> FilterMap<Error> in
            if case let .error(err) = event {
                return .map(err)
            }
            return .ignore
        }
        let signal = Observable.merge(
            next.map { _ in },
            err.map { _ in }
        )
        return (next, err, signal)
}

func mergeControlEvent<T>(_ events: [ControlEvent<T>]) -> ControlEvent<T> {
    let source = Observable.merge(events.map { $0.asObservable() })
    return ControlEvent(events: source)
}

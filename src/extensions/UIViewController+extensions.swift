//
//  UIViewController+extensions.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/18.
//

import RxSwift
import RxCocoa


extension Reactive where Base: UIViewController {
    var viewWillFirstTimeAppear: ControlEvent<()> {
        let source = methodInvoked(#selector(Base.viewWillAppear)).map { _ in }.take(1)
        return ControlEvent(events: source)
    }
}

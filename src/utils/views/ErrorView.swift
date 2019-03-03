//
//  ErrorView.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/09.
//

import UIKit
import RxSwift
import RxCocoa


class ErrorView: UIView {

    let label = UILabel()
    let btn = UIButton(type: .system)

    private init() {
        super.init(frame: .zero)
        label.text = "Network error, please retry"
        label.textColor = .black

        btn.setTitle("Reload", for: .normal)

        let stackView = UIStackView(arrangedSubviews: [label, btn])
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.centerInSuperView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ErrorView {
    static func viewWithReloadTrigger() -> (UIView, ControlEvent<()>) {
        let view = ErrorView()
        return (view, view.btn.rx.tap)
    }
}

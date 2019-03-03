//
//  EmptyView.swift
//  InfiniteKit
//
//  Created by duan on 2019/03/03.
//

import UIKit
import RxSwift
import RxCocoa



class EmptyView: UIView {

    let label = UILabel()
    let btn = UIButton(type: .system)

    private init() {
        super.init(frame: .zero)
        label.text = "No data available"
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

extension EmptyView {
    static func viewWithReloadTrigger() -> (UIView, ControlEvent<()>) {
        let view = EmptyView()
        return (view, view.btn.rx.tap)
    }
}

//
//  LoadingView.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/08.
//

import UIKit


class LoadingView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        addSubview(indicator)
        indicator.centerInSuperView()
        indicator.startAnimating()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


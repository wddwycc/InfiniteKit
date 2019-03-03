//
//  InfiniteList+Config.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/24.
//

import UIKit
import RxSwift
import RxCocoa


extension InfiniteList {
    public typealias ViewWithTrigger = (UIView, ControlEvent<()>)

    public struct Config {
        public let initFetch: InitFetch
        public let nextFetch: NextFetch
        public let dataExtractor: DataExtractor

        public let cellDecorator: CellDecorator
        public var refreshControl: UIRefreshControl? = nil
        public var loadingView: UIView? = nil

        public var emptyViewAndReloadTrigger: ViewWithTrigger? = nil
        public var errorViewAndReloadTrigger: ViewWithTrigger? = nil
        // TODO: Support custom load more view.

        public var autoDeselect: Bool = true

        public init(
            initFetch: @escaping InitFetch,
            nextFetch: @escaping NextFetch,
            dataExtractor: @escaping DataExtractor,
            cellDecorator: @escaping CellDecorator
        ) {
            self.initFetch = initFetch
            self.nextFetch = nextFetch
            self.dataExtractor = dataExtractor
            self.cellDecorator = cellDecorator
        }
    }
}

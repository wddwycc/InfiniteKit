//
//  InfiniteList.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/08.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt
import RxDataSources


public class InfiniteList<Cell: UITableViewCell, DataPack, CellModel>: UIViewController {

    public typealias InitFetch = () -> Single<DataPack>
    public typealias NextFetch = (DataPack) -> Single<DataPack?>
    public typealias DataExtractor = ([DataPack]) -> [CellModel]
    public typealias CellDecorator = (Cell, CellModel) -> Void

    public let tableView = UITableView()

    public var modelSelected: ControlEvent<CellModel> {
        return tableView.rx.modelSelected(CellModel.self)
    }

    private let disposeBag = DisposeBag()
    private let cellIdentifier = "Cell"

    public init(config: Config) {
        super.init(nibName: nil, bundle: nil)

        let refreshControl = config.refreshControl ?? UIRefreshControl()

        tableView.refreshControl = refreshControl
        tableView.register(Cell.self, forCellReuseIdentifier: cellIdentifier)
        view.addSubview(tableView)
        tableView.edgesToSuperView()

        let loadingView = config.loadingView ?? LoadingView()
        view.addSubview(loadingView)
        loadingView.edgesToSuperView()

        let (errorView, errorViewReloadTrigger) = config.errorViewAndReloadTrigger
            ?? ErrorView.viewWithReloadTrigger()
        view.addSubview(errorView)
        errorView.edgesToSuperView()

        let (emptyView, emptyViewReloadTrigger) = config.emptyViewAndReloadTrigger
            ?? EmptyView.viewWithReloadTrigger()
        view.addSubview(emptyView)
        emptyView.edgesToSuperView()

        let loadMoreTrigger = PublishRelay<Void>()

        let (
            cellModels, reloading, refreshing, loadingMore, erroring
        ) = InfiniteList.pipe(
            initTrigger: rx.viewWillFirstTimeAppear,
            reloadTrigger: mergeControlEvent([errorViewReloadTrigger, emptyViewReloadTrigger]),
            refreshTrigger: refreshControl.rx.controlEvent(.valueChanged),
            loadMoreTrigger: ControlEvent(events: loadMoreTrigger),
            config: config,
            disposeBag: disposeBag
        )

        tableView.rx.willDisplayCell
            .withLatestFrom(cellModels.asObservable()) { willDisplayCell, cellModels in
                let (_, indexPath) = willDisplayCell
                return indexPath.row >= cellModels.count - 2
            }
            .filter { $0 }
            .map { _ in }
            .bind(to: loadMoreTrigger)
            .disposed(by: disposeBag)

        cellModels
            .drive(tableView.rx.items(cellIdentifier: cellIdentifier)) {
                index, model, cell in
                guard let cell = cell as? Cell else { return }
                config.cellDecorator(cell, model)
            }
            .disposed(by: disposeBag)
        reloading.map { !$0 }.drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        refreshing.asObservable().pairwise()
            .filter { $0 && !$1 }
            .subscribe(onNext: { [weak refreshControl] _ in
                refreshControl?.endRefreshing()
            })
            .disposed(by: disposeBag)
        loadingMore.drive(onNext: { [unowned tableView] (loadingMore) in
            if loadingMore {
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                spinner.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
                tableView.tableFooterView = spinner
            } else {
                tableView.tableFooterView = UIView()
            }
        }).disposed(by: disposeBag)
        erroring.map { !$0 }.drive(errorView.rx.isHidden).disposed(by: disposeBag)

        let shouldHideData = Observable
            .combineLatest(reloading.asObservable(), erroring.asObservable())
            .map { $0 || $1 }
            .share()

        shouldHideData
            .bind(to: tableView.rx.isHidden)
            .disposed(by: disposeBag)

        Observable.combineLatest(shouldHideData, cellModels.asObservable())
            .map { !$0 && $1.count == 0 }
            .map { !$0 }
            .bind(to: emptyView.rx.isHidden)
            .disposed(by: disposeBag)

        if config.autoDeselect {
            tableView.rx.itemSelected
                .subscribe(onNext: { [unowned self] indexPath in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                })
                .disposed(by: disposeBag)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  InfiniteList+ViewModel.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/24.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt


extension InfiniteList {
    static func pipe(
        initTrigger: ControlEvent<()>,
        reloadTrigger: ControlEvent<()>,
        refreshTrigger: ControlEvent<()>,
        loadMoreTrigger: ControlEvent<()>,
        config: Config,
        disposeBag: DisposeBag
    ) -> (
        cellModels: Driver<[CellModel]>,
        reloading: Driver<Bool>,
        refreshing: Driver<Bool>,
        loadingMore: Driver<Bool>,
        erroring: Driver<Bool>
    ) {
        let dataPacksRelay = BehaviorRelay<[DataPack]>(value: [])
        let reloading = BehaviorRelay(value: false)
        let refreshing = BehaviorRelay(value: false)
        let loadingMore = BehaviorRelay(value: false)
        let erroring = BehaviorRelay(value: false)

        let reload = Observable
            .merge(initTrigger.asObservable(), reloadTrigger.asObservable())
            .flatMapLatest { config.initFetch().asObservable().materialize() }
            .share()
        let (reloadData, reloadErr, reloadResp) = forkSignal(observable: reload)

        let refresh = refreshTrigger
            .flatMapLatest { config.initFetch().asObservable().materialize() }
            .share()
        let (refreshData, refreshErr, refreshResp) = forkSignal(observable: refresh)

        let loadMoreTrigger_ = loadMoreTrigger
            .withLatestFrom(loadingMore)
            .filter { !$0 }
            .withLatestFrom(dataPacksRelay)
            .filterMap { dataPacks -> FilterMap<DataPack> in
                if let last = dataPacks.last { return .map(last) }
                return .ignore
        }
        let loadMore = loadMoreTrigger_
            .flatMapLatest {
                config.nextFetch($0).asObservable().unwrap().materialize()
            }
            .share()
        // TODO: handling load-more error
        let (loadMoreData, _, loadMoreResp) = forkSignal(observable: loadMore)

        Observable
            .merge(
                Observable.merge(reloadData, refreshData).map { [$0] },
                loadMoreData.withLatestFrom(dataPacksRelay) { $1 + [$0] }
            )
            .bind(to: dataPacksRelay)
            .disposed(by: disposeBag)

        let cellModels = dataPacksRelay.map(config.dataExtractor)

        Observable
            .merge(
                initTrigger.map { true },
                reloadTrigger.map { true },
                reloadResp.map { _ in false }
            )
            .bind(to: reloading)
            .disposed(by: disposeBag)
        Observable
            .merge(
                refreshTrigger.map { true },
                refreshResp.map { _ in false }
            )
            .bind(to: refreshing)
            .disposed(by: disposeBag)
        Observable
            .merge(
                refreshTrigger.map { _ in false },
                reloadTrigger.map { _ in false },
                reloadErr.map { _ in true },
                refreshErr.map { _ in true }
            )
            .bind(to: erroring)
            .disposed(by: disposeBag)
        Observable
            .merge(
                loadMoreTrigger_.map { _ in true },
                loadMoreResp.map { _ in false }
            )
            .bind(to: loadingMore)
            .disposed(by: disposeBag)

        return (
            cellModels: cellModels.asDriver(onErrorDriveWith: .empty()),
            reloading: reloading.asDriver().distinctUntilChanged(),
            refreshing: refreshing.asDriver().distinctUntilChanged(),
            loadingMore: loadingMore.asDriver().distinctUntilChanged(),
            erroring: erroring.asDriver().distinctUntilChanged()
        )
    }
}

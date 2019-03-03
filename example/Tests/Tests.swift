//
//  Tests.swift
//  InfiniteKit_Tests
//
//  Created by duan on 2019/02/24.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
@testable import InfiniteKit


fileprivate class Cell: UITableViewCell {}
fileprivate struct CellModel: Codable, Hashable {
    let id: Int
}
fileprivate typealias DataPack = (data: [CellModel], offset: Int)
fileprivate typealias List = InfiniteList<Cell, DataPack, CellModel>
fileprivate let dataExtractor: List.DataExtractor = {
    let flattened = $0.map { $0.data }.flatMap { $0 }
    return Array(Set(flattened)).sorted(by: { $0.id < $1.id })
}

fileprivate func testablePipe(
    initTrigger: ControlEvent<()> = ControlEvent(events: Observable.empty()),
    reloadTrigger: ControlEvent<()> = ControlEvent(events: Observable.empty()),
    refreshTrigger: ControlEvent<()> = ControlEvent(events: Observable.empty()),
    loadMoreTrigger: ControlEvent<()> = ControlEvent(events: Observable.empty()),
    config: List.Config,
    scheduler: TestScheduler,
    disposeBag: DisposeBag
) -> (
    cellModels: TestableObserver<[CellModel]>,
    reloading: TestableObserver<Bool>,
    refreshing: TestableObserver<Bool>,
    loadingMore: TestableObserver<Bool>,
    erroring: TestableObserver<Bool>
) {
    let (
        _cellModels, _reloading, _refreshing, _loadingMore, _erroring
    ) = List.pipe(
        initTrigger: initTrigger,
        reloadTrigger: reloadTrigger,
        refreshTrigger: refreshTrigger,
        loadMoreTrigger: loadMoreTrigger,
        config: config, disposeBag: disposeBag
    )

    let cellModels = scheduler.createObserver([CellModel].self)
    _cellModels.drive(cellModels).disposed(by: disposeBag)
    let reloading = scheduler.createObserver(Bool.self)
    _reloading.drive(reloading).disposed(by: disposeBag)
    let refreshing = scheduler.createObserver(Bool.self)
    _refreshing.drive(refreshing).disposed(by: disposeBag)
    let loadingMore = scheduler.createObserver(Bool.self)
    _loadingMore.drive(loadingMore).disposed(by: disposeBag)
    let erroring = scheduler.createObserver(Bool.self)
    _erroring.drive(erroring).disposed(by: disposeBag)

    return (
        cellModels: cellModels,
        reloading: reloading,
        refreshing: refreshing,
        loadingMore: loadingMore,
        erroring: erroring
    )
}


fileprivate let firstDataPack: DataPack = (data: (1...2).map { CellModel(id: $0) }, offset: 2)
fileprivate let secondDataPack: DataPack = (data: (3...4).map { CellModel(id: $0) }, offset: 4)

fileprivate let timeToInit: TestTime = 10
fileprivate let reqDuration: TestTime = 100

fileprivate func initFetchToSucceed(scheduler: TestScheduler) -> List.InitFetch {
    return {
        scheduler.createColdObservable([
            .next(reqDuration, firstDataPack),
            .completed(reqDuration),
        ]).asSingle()
    }
}

fileprivate func initFetchToFail(scheduler: TestScheduler) -> List.InitFetch {
    return {
        scheduler.createColdObservable([
            Recorded<Event<DataPack>>.error(reqDuration, RxError.timeout),
        ]).asSingle()
    }
}

fileprivate func nextFetchToSucceed(scheduler: TestScheduler) -> List.NextFetch {
    return { prev in
        return scheduler.createColdObservable([
            .next(reqDuration, secondDataPack),
            .completed(reqDuration),
        ]).asSingle()
    }
}

fileprivate func nextFetchToFail(scheduler: TestScheduler) -> List.NextFetch {
    return { _ in
        scheduler.createColdObservable([
            Recorded<Event<DataPack?>>.error(reqDuration, RxError.timeout),
        ]).asSingle()
    }
}

class Tests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInitLoadSuccess() {
        let initTrigger = scheduler.createColdObservable([.next(timeToInit, ())])
        let reloadTrigger = PublishRelay<Void>()
        let refreshTrigger = PublishRelay<Void>()

        let config = List.Config(
            initFetch: initFetchToSucceed(scheduler: scheduler),
            nextFetch: nextFetchToSucceed(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )

        let (
            cellModels, reloading, refreshing, _, erroring
        ) = testablePipe(
            initTrigger: ControlEvent(events: initTrigger),
            reloadTrigger: ControlEvent(events: reloadTrigger),
            refreshTrigger: ControlEvent(events: refreshTrigger),
            config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            .next(timeToInit + reqDuration, firstDataPack.data),
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false)
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false)
            ])
    }

    func testInitLoadFailed() {
        let initTrigger = scheduler.createColdObservable([.next(10, ())])
        let reloadTrigger = PublishRelay<Void>()
        let refreshTrigger = PublishRelay<Void>()

        let config = List.Config(
            initFetch: initFetchToFail(scheduler: scheduler),
            nextFetch: nextFetchToSucceed(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )
        let (
            cellModels, reloading, refreshing, _, erroring
        ) = testablePipe(
            initTrigger: ControlEvent(events: initTrigger),
            reloadTrigger: ControlEvent(events: reloadTrigger),
            refreshTrigger: ControlEvent(events: refreshTrigger),
            config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false)
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false),
            .next(timeToInit + reqDuration, true),
            ])
    }

    func testReloadSuccess() {
        let timeToReload = 200

        let initTrigger = scheduler.createColdObservable([.next(10, ())])
        let reloadTrigger = scheduler.createColdObservable([.next(timeToReload, ())])
        let refreshTrigger = PublishRelay<Void>()

        var isFirstFetch = true
        let initFetch: List.InitFetch = {
            if isFirstFetch {
                isFirstFetch = false
                return initFetchToFail(scheduler: self.scheduler)()
            } else {
                return initFetchToSucceed(scheduler: self.scheduler)()
            }
        }

        let config = List.Config(
            initFetch: initFetch,
            nextFetch: nextFetchToSucceed(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )
        let (
            cellModels, reloading, refreshing, _, erroring
        ) = testablePipe(
            initTrigger: ControlEvent(events: initTrigger),
            reloadTrigger: ControlEvent(events: reloadTrigger),
            refreshTrigger: ControlEvent(events: refreshTrigger),
            config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            .next(timeToReload + reqDuration, firstDataPack.data),
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            .next(timeToReload, true),
            .next(timeToReload + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false)
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false),
            .next(timeToInit + reqDuration, true),
            .next(timeToReload, false),
            ])
    }

    func testReloadFailed() {
        let timeToReload = 200

        let initTrigger = scheduler.createColdObservable([.next(10, ())])
        let reloadTrigger = scheduler.createColdObservable([.next(timeToReload, ())])
        let refreshTrigger = PublishRelay<Void>()

        let config = List.Config(
            initFetch: initFetchToFail(scheduler: scheduler),
            nextFetch: nextFetchToSucceed(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )
        let (
            cellModels, reloading, refreshing, _, erroring
        ) = testablePipe(
            initTrigger: ControlEvent(events: initTrigger),
            reloadTrigger: ControlEvent(events: reloadTrigger),
            refreshTrigger: ControlEvent(events: refreshTrigger),
            config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            .next(timeToReload, true),
            .next(timeToReload + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false)
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false),
            .next(timeToInit + reqDuration, true),
            .next(timeToReload, false),
            .next(timeToReload + reqDuration, true),
            ])
    }

    func testRefreshSuccess() {
        let timeToRefresh = 200

        let initTrigger = scheduler.createColdObservable([.next(timeToInit, ())])
        let reloadTrigger = PublishRelay<Void>()
        let refreshTrigger = scheduler.createColdObservable([.next(timeToRefresh, ())])

        let config = List.Config(
            initFetch: initFetchToSucceed(scheduler: scheduler),
            nextFetch: nextFetchToSucceed(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )

        let (
            cellModels, reloading, refreshing, _, erroring
        ) = testablePipe(
            initTrigger: ControlEvent(events: initTrigger),
            reloadTrigger: ControlEvent(events: reloadTrigger),
            refreshTrigger: ControlEvent(events: refreshTrigger),
            config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            .next(timeToInit + reqDuration, firstDataPack.data),
            .next(timeToRefresh + reqDuration, firstDataPack.data),
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false),
            .next(timeToRefresh, true),
            .next(timeToRefresh + reqDuration, false)
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false)
            ])
    }

    func testRefreshFailed() {
        let timeToRefresh = 200

        let initTrigger = scheduler.createColdObservable([.next(timeToInit, ())])
        let reloadTrigger = PublishRelay<Void>()
        let refreshTrigger = scheduler.createColdObservable([.next(timeToRefresh, ())])

        var isFirstFetch = true
        let initFetch: List.InitFetch = {
            if isFirstFetch {
                isFirstFetch = false
                return initFetchToSucceed(scheduler: self.scheduler)()
            } else {
                return initFetchToFail(scheduler: self.scheduler)()
            }
        }

        let config = List.Config(
            initFetch: initFetch,
            nextFetch: nextFetchToSucceed(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )

        let (
            cellModels, reloading, refreshing, _, erroring
        ) = testablePipe(
            initTrigger: ControlEvent(events: initTrigger),
            reloadTrigger: ControlEvent(events: reloadTrigger),
            refreshTrigger: ControlEvent(events: refreshTrigger),
            config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            .next(timeToInit + reqDuration, firstDataPack.data),
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false),
            .next(timeToRefresh, true),
            .next(timeToRefresh + reqDuration, false),
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false),
            .next(timeToRefresh + reqDuration, true),
            ])
    }

    func testLoadMoreSuccess() {
        let timeToLoadMore = 200

        let initTrigger = scheduler.createColdObservable([.next(timeToInit, ())])
        let loadMoreTrigger = scheduler.createColdObservable([.next(timeToLoadMore, ())])

        let config = List.Config(
            initFetch: initFetchToSucceed(scheduler: scheduler),
            nextFetch: nextFetchToSucceed(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )

        let (
            cellModels, reloading, refreshing, loadingMore, erroring
        ) = testablePipe(
            initTrigger: ControlEvent(events: initTrigger),
            loadMoreTrigger: ControlEvent(events: loadMoreTrigger),
            config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            .next(timeToInit + reqDuration, firstDataPack.data),
            .next(timeToLoadMore + reqDuration, firstDataPack.data + secondDataPack.data)
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false),
            ])
        XCTAssertEqual(loadingMore.events, [
            .next(0, false),
            .next(timeToLoadMore, true),
            .next(timeToLoadMore + reqDuration, false),
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false),
            ])

    }
    func testLoadMoreFailed() {
        let timeToLoadMore = 200

        let initTrigger = scheduler.createColdObservable([.next(timeToInit, ())])
        let loadMoreTrigger = scheduler.createColdObservable([.next(timeToLoadMore, ())])

        let config = List.Config(
            initFetch: initFetchToSucceed(scheduler: scheduler),
            nextFetch: nextFetchToFail(scheduler: scheduler),
            dataExtractor: dataExtractor,
            cellDecorator: { _,_ in }
        )

        let (
        cellModels, reloading, refreshing, loadingMore, erroring
            ) = testablePipe(
                initTrigger: ControlEvent(events: initTrigger),
                loadMoreTrigger: ControlEvent(events: loadMoreTrigger),
                config: config, scheduler: scheduler, disposeBag: disposeBag
        )

        scheduler.start()

        XCTAssertEqual(cellModels.events, [
            .next(0, []),
            .next(timeToInit + reqDuration, firstDataPack.data),
            ])
        XCTAssertEqual(reloading.events, [
            .next(0, false),
            .next(timeToInit, true),
            .next(timeToInit + reqDuration, false),
            ])
        XCTAssertEqual(refreshing.events, [
            .next(0, false),
            ])
        XCTAssertEqual(loadingMore.events, [
            .next(0, false),
            .next(timeToLoadMore, true),
            .next(timeToLoadMore + reqDuration, false),
            ])
        XCTAssertEqual(erroring.events, [
            .next(0, false),
            ])
    }
}

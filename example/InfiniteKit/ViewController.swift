//
//  ViewController.swift
//  InfiniteKit
//
//  Created by duan on 02/08/2019.
//

import UIKit
import RxSwift
import RxCocoa
import InfiniteKit


fileprivate typealias Cell = UITableViewCell
fileprivate struct CellModel: Codable, Hashable {
    let id: Int
    let login: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
fileprivate typealias DataPack = (data: [CellModel], offset: Int)
fileprivate typealias List = InfiniteList<Cell, DataPack, CellModel>

fileprivate let initFetch: List.InitFetch = {
    let url = "https://api.github.com/users"
    let req = genReq(url: url)
//    return Single.just((data: [], offset: 0))
//        .delay(1, scheduler: MainScheduler.instance)
    return sendReq(req, decodeWith: [CellModel].self)
        .map { (data: $0, offset: $0.count) }
        .asSingle()
}
fileprivate let nextFetch: List.NextFetch = { lastDataPack in
    let url = "https://api.github.com/users"
    let params = ["since": String(lastDataPack.offset)]
    let req = genReq(url: url, params: params)
    return sendReq(req, decodeWith: [CellModel].self)
        .map { (data: $0, offset: lastDataPack.offset + $0.count) }
        .asSingle()
}
fileprivate let dataExtractor: List.DataExtractor = { dataPacks in
    let flattened = dataPacks.map { $0.data }.flatMap { $0 }
    // remove duplicate & order asc by id
    return Array(Set(flattened)).sorted(by: { $0.id < $1.id })
}
fileprivate let cellDecorator: List.CellDecorator = { cell, model in
    cell.textLabel?.text = model.login
}
fileprivate let config = List.Config(
    initFetch: initFetch,
    nextFetch: nextFetch,
    dataExtractor: dataExtractor,
    cellDecorator: cellDecorator
)

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Github Users"
        view.backgroundColor = .white

        let list = List(config: config)
        addChildViewController(list)
        view.addSubview(list.view)
        view.edgesToSuperView()
    }
}

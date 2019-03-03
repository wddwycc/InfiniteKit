![logo](https://raw.githubusercontent.com/wddwycc/InfiniteKit/master/misc/header-logo.png)

[![Version](https://img.shields.io/cocoapods/v/InfiniteKit.svg?style=flat)](https://cocoapods.org/pods/InfiniteKit)
[![License](https://img.shields.io/cocoapods/l/InfiniteKit.svg?style=flat)](https://cocoapods.org/pods/InfiniteKit)
[![Platform](https://img.shields.io/cocoapods/p/InfiniteKit.svg?style=flat)](https://cocoapods.org/pods/InfiniteKit)



## Features

- [x] Create `Infinite Scroll` in declarative style with much less code
- [x] All states related UI covered by the library by default
- [x] Fully customizable
- [x] Well tested using RxTest


## Why

In real world iOS applications, most data from server are displayed with `UITableView` and `UICollectionView`. To create a full-featured infinite scroll using server data, developers should consider implementing many things:

- `Loading view`: display when reload or first time load
- `Empty view`: display when server returns empty data
- `Error view`: display when network error occurs
- `Pull to refresh`
- `Pull to load more`

Most junior developers would build up the data flow repeatedly, which would eventually lead to code redundancy and duplicated test cases.  
In most cases, Infinite scroll can be abstracted into a common pattern.  
InfiniteKit exists to let developers use this pattern easily, create full-featured infinite scroll faster, and in declarative style.

Let's build up a infinite scroll to list github users using [Github Open API](https://developer.github.com/v3/users/#get-all-users):

Firstly, take a look the abstraction in InfiniteKit `InfiniteList<Cell, DataPack, CellModel>`:

- `Cell` is subclass of `UITableViewCell`
- `DataPack` represents data package receieved from server
- `CellModel` should be extracted from `DataPack` and used to render cell

We declare necessary types:

```swift
typealias Cell = UITableViewCell
struct CellModel: Codable {
    let id: Int
    let login: String
}
typealias DataPack = (data: [CellModel], offset: Int)
typealias List = InfiniteList<Cell, DataPack, CellModel>
```

Next we declare how we gonna fetch data and use them to render our cells, with only four closures:

- `List.InitFetch`
- `List.NextFetch`
- `List.DataExtractor`
- `List.CellDecorator`

`List.InitFetch` is alias of `() -> Single<DataPack>`, generates first data fetch.

```swift
let initFetch: List.InitFetch = {
    let url = "https://api.github.com/users"
    let req = genReq(url: url)
    return sendReq(req, decodeWith: [CellModel].self)
        .map { (data: $0, offset: $0.count) }
        .asSingle()
}
```

`List.NextFetch` is alias of `(DataPack) -> Single<DataPack?>`, generates data fetch based on the last fetched result, return nil if no more data is available.

```swift
let nextFetch: List.NextFetch = { lastDataPack in
    let url = "https://api.github.com/users"
    let params = ["since": String(lastDataPack.offset)]
    let req = genReq(url: url, params: params)
    return sendReq(req, decodeWith: [CellModel].self)
        .map { (data: $0, offset: lastDataPack.offset + $0.count) }
        .asSingle()
}
```

`List.DataExtractor` is alias of `([DataPack]) -> [CellModel]`, to map data packs to cell models.

```swift
let dataExtractor: List.DataExtractor = { dataPacks in
    let flattened = dataPacks.map { $0.data }.flatMap { $0 }
    // remove duplicate & order asc by id
    return Array(Set(flattened)).sorted(by: { $0.id < $1.id })
}
```

`List.CellDecorator` is alias of `(Cell, CellModel) -> Void`, to update cells using model.

```swift
let cellDecorator: List.CellDecorator = { cell, model in
    cell.textLabel?.text = model.login
}
```

We now can use this config to create our `List`, which is subclass of `ViewController`:

```swift
let config = List.Config(
    initFetch: initFetch,
    nextFetch: nextFetch,
    dataExtractor: dataExtractor,
    cellDecorator: cellDecorator
)
let list = List(config: config)
```

The `List` now has default `Loading view`, `Empty view`, `Error view`, `Pull to refresh`, `Pull to load more`, and the core data flow is well tested already by the library.

You can customize the `List` by configure `List.Config`

```swift
config.refreshControl // UIRefreshControl
config.loadingView // UIView
config.emptyViewAndReloadTrigger // (UIView, ControlEvent<()>)
config.errorViewAndReloadTrigger // (UIView, ControlEvent<()>)
```

## Todo

- [x] InfiniteList
- [ ] InfiniteSectionList
- [ ] InfiniteCollection
- [ ] InfiniteSecitonCollection

## Example

To run the example project, clone the repo, and run `pod install` from the example directory first.

## Requirements

## Installation

InfiniteKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'InfiniteKit'
```

## Author

wddwycc, wddwyss@gmail.com

## License

InfiniteKit is available under the MIT license. See the LICENSE file for more info.

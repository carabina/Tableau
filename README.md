# Tableau

Tableau is an RxSwift-compatible library for making your table and collection view setup routine smaller, more declarative, and more type safe that lets you switch from the tired data source / delegate routine to a cleaner function chain that reads like a sentence.

## The basics
At the bare minimum, here's what a super simple, static, section-less table view looks like with Tableau:

```swift
// MyViewController.swift

var models: [MyModel] = ...

let binder = TableViewBinder(tableView: self.tableView)
binder.onTable()
    .bind(cellType: MyCell.self, models: models)
    .onCellDequeue { (row: Int, cell: MyCell, model: MyModel)
        // setup the 'cell' with the 'model'
    }
    .onTapped { (row: Int, cell: MyCell, model: MyModel)
        // e.g. go to a detail view controller with the 'model'
    }
```

Easy! Just from this example, you can see how your normal data source / delegate methods are shortened into a much more legible phrase. This can be read as *"Okay binder, on the entire table, bind the `MyCell` cell type based on the model objects from the given array. Whenever a cell is dequeued, give me the model object it was dequeued for and let me configure the cell. Whenever a cell is tapped, I want this to happen."* Everything is type safe and you don't need to map rows to model array indexes.

## Updating tables

For tables setup without using RxSwift that need dynamic updates, you just need to, at the end of your binding chain, add a `.createUpdateCallback()` call and save the resulting closure somewhere to call later, like this:

```swift
var updateTable: ([MyModel]) -> Void

self.updateTable = binder.onTable()
    .bind(cellType: MyCell.self, models: models)
    .createUpdateCallback()
    
...

self.updateTable(newModels)
```

For those using RxSwift, auto-updating table views are possible with the use of observables. The same example (with updating) with the Rx variant of Tableau can be done like this:

```swift
// MyViewController.swift

var models: Observable<[MyModel]> = ...

let binder = TableViewBinder(tableView: self.tableView)
binder.onTable()
    .rx.bind(cellType: MyCell.self, models: models)
    .onCellDequeue { (row: Int, cell: MyCell, model: MyModel)
        // setup the 'cell' with the 'model'
    }
    .onTapped { (row: Int, cell: MyCell, model: MyModel)
        // e.g. go to a detail view controller with the 'model'
    }
```

Here, the 'table view binder' object will subscribe to changes to the `models` observable array and auto-update the table.

## Getting a little more advanced

Tableau can do a lot more than that, though. To really demonstrate it, we'll look at a more complex example of what your table and collection views can look like. Let's say we're making a home view for a banking app that lists all of a user's accounts in different sections according to the account type. Checking and savings accounts have a shared model type (`Account`) and cell type (`AccountCell`),  but investing accounts have their own model (`InvestingAccount`) and cell type (`InvestingCell`). Just to make it complicated, your designers want a banner at the top (`BannerCell`) too. Your analytics team also wants to know anytime a cell is tapped on the home page. Here's what that can look like:

```swift
// HomeViewController.swift

enum Section: TableViewSection {
    case banner
    case checking
    case savings
    case investing
}

let checkingAccounts: Observable<[Account]> = ...
let savingsAccounts: Observable<[Account]> = ...
let investingAccounts: Observable<[InvestingAccount]> = ...
let bannerViewModel: BannerCell.ViewModel = ...

let binder = SectionedTableViewBinder(tableView: self.tableView, sectionedBy: Section.self)

binder.onSection(.banner)
    .bind(cellType: BannerCell.self, viewModels: [bannerViewModel])

binder.onSections([.checking, .savings])
    .rx.bind(cellType: AccountCell.self, models: [
        .checking: checkingAccounts,
        .savings: savingsAccounts
    ])
    .headerTitles([
        .checking: "CHECKING",
        .savings: "SAVINGS"
    ])
    .onCellDequeue { (section: Section, row: Int, cell: AccountCell, account: Account) in
        // setup the 'account cell' with the 'account' object
    }
    .onTapped { (section: Section, row: Int, cell: AccountCell, account: Account) in
        // go to an 'account details' view controller with the account
    }
    
binder.onSection(.investing)
    .rx.bind(cellType: InvestingCell.self, models: investingAccounts)
    .headerTitle("INVESTING")
    .onCellDequeue { (row: Int, cell: InvestingCell, account: InvestingAccount) in
        // setup the 'investing cell' with the 'account' object
    }
    .onTapped { (section: Section, row: Int, cell: InvestingCell, account: InvestingAccount) in
        // go to an 'account details' view controller with the account
    }
    
binder.onAllSections()
    .onTapped { (section: Section, row: Int, cell: UITableViewCell)
        // analytics stuff
    }
```

While that's pretty dense, it's still pretty legible as it is, and reads a lot like our given requirements. This is read something like *"First, create a sectioned table binder whose sections are cases of the `Section` enum. Then, in the 'banner' section, bind the `BannerCell` type with the given banner view model. Next, for both the 'checking' and 'savings' sections, bind the `AccountCell` cell type based on these model arrays. Set the section titles for these sections to these strings. Whenever a cell is dequeued, run this block of code. Whenever a cell is tapped, run this other block of code. Now, on just the 'investing' section, bind the `InvestingCell` cell type with the models from this array, running these code blocks when cells are dequeued or tapped. Finally, on any section, run this other code block whenever a cell is tapped."*

While this example is pretty self-explanatory in many ways, to give it a bit more detail, here you can see:
- Sections of a table view correspond to cases of an enum so it's easier to read and more flexible than using integers
- Supports different model types for different sections of your table view with the ability to batch similar sections in one binding chain
- Ability to add multiple handlers for some events like 'on tapped'
- You're always dealing with the type you want - sections are returned as cases of your 'section' enum and cells/models are of the type you give

## Using view models

Tableau has built-in support for using view models with your cells to make them more reusable and makes your binding chains a bit smaller by removing the need for the `onCellDequeue` call. The idea is to make your cells conform to `ViewModelBindable` then give them a `ViewModel` type and property to set. This also reduces boilerplate by removing the need to, every time you use this cell type, manually set each of the cell's exposed labels or image views - all that configuration logic happens in one place in your cell, like this:

```swift
// MyCell.swift

class MyCell: UITableViewCell, ViewModelBindable {
    struct ViewModel {
        let title: String
        let subtitle: String
    }
    
    var viewModel: ViewModel? {
        didSet {
            // setup labels, etc
        }
    }
}
```
Your binding chain can then either be passed in an array of view models as seen in the previous example with the `.banner` section, or, if your cells are based off of raw data models, you can pass a mapping function into the binding chain, like this:

```swift
let models: [MyModel] = ...
let modelToViewModel = { (model: MyModel) -> MyCell.ViewModel in
    // create a view model for `MyCell` from the model and return
}

binder.onSection(.someSection)
    .bind(cellType: MyCell.self, models: models, mapToViewModelBy: modelToViewModel)
```
The binder will then take care of setting the `viewModel` property of your cells automatically - no `onCellDequeue` call required.

That's not all, though. Tableau has a number of other features:
- Easily hot swap or reload sections by changing the binder's `displayedSections` property
- Support for static sections via an enum or dynamic sections via a section model struct you define
- Type safe updating of cells in a section via callback closures created during binding
- RxSwift support for updating sections from `Observable` arrays for truly declarative setup
- Automatic diffing between updates to the table's underlying models (coming soon!)
- `UICollectionView` and `UIPickerView` support (coming soon!)

## Installation

Tableau (will be) available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Tableau'
```

## Author

Aaron Bosnjak (aaron.bosnjak707@gmail.com)

## License

Tableau is available under the MIT license. See the LICENSE file for more info.

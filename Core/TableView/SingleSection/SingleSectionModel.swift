import UIKit

/**
 An object used to continue a binding chain.
 
 This is a throwaway object created when a table view binder's `onSection(_:)` method is called. This object declares a
 number of methods that take a binding handler and give it to the original table view binder to store for callback. A
 reference to this object should not be kept and should only be used in a binding chain.
*/
public class TableViewModelSingleSectionBinder<C: UITableViewCell, S: TableViewSection, M>
    : TableViewSingleSectionBinder<C, S>
{    
    /**
     Adds a handler to be called whenever a cell in the declared section is tapped.
     
     The handler is called whenever a cell in the section is tapped, passing in the row and cell that was tapped, along
     with the raw model object associated with the cell. The cell will be safely cast to the cell type bound to the
     section if this method is called in a chain after the `bind(cellType:viewModels:)` method.
     
     Note that this `onTapped` variation with the raw model object is only available if the `bind(cellType:models:)`
     method was used to bind the cell type to the section.
     
     - parameter handler: The closure to be called whenever a cell is tapped in the bound section.
     - parameter row: The row of the cell that was tapped.
     - parameter tappedCell: The cell that was tapped.
     - parameter model: The model object that the cell was dequeued to represent in the table.
     - returns: A section binder to continue the binding chain with.
    */
    @discardableResult
    public func onTapped(_ handler: @escaping (_ row: Int, _ tappedCell: C, _ model: M) -> Void)
        -> TableViewModelSingleSectionBinder<C, S, M>
    {
        let section = self.section
        let tappedHandler: CellTapCallback<S> = {  [weak binder = self.binder] (_, row, cell) in
            guard let cell = cell as? C, let model = binder?.currentDataModel.sectionCellModels[section]?[row] as? M else {
                assertionFailure("ERROR: Cell or model wasn't the right type; something went awry!")
                return
            }
            handler(row, cell, model)
        }
        
        self.binder.handlers.sectionCellTappedCallbacks[section] = tappedHandler
        return self
    }
    
    /**
     Adds a handler to be called whenever a cell is dequeued in the declared section.
     
     The handler is called whenever a cell in the section is dequeued, passing in the row, the dequeued cell, and the
     model object that the cell was dequeued to represent. The cell will be cast to the cell type bound to the section
     if this method is called in a chain after the `bind(cellType:viewModels:)` method. This method can be used to
     perform any additional configuration of the cell.
     
     - parameter handler: The closure to be called whenever a cell is dequeued in the bound section.
     - parameter row: The row of the cell that was dequeued.
     - parameter dequeuedCell: The cell that was dequeued that can now be configured.
     - parameter model: The model object that the cell was dequeued to represent in the table.
     - returns: A section binder to continue the binding chain with.
     */
    @discardableResult
    public func onCellDequeue(_ handler: @escaping (_ row: Int, _ dequeuedCell: C, _ model: M) -> Void)
        -> TableViewModelSingleSectionBinder<C, S, M>
    {
        let section = self.section
        let dequeueCallback: CellDequeueCallback<S> = { [weak binder = self.binder] (_, row, cell) in
            guard let cell = cell as? C, let model = binder?.currentDataModel.sectionCellModels[section]?[row] as? M else {
                assertionFailure("ERROR: Cell wasn't the right type; something went awry!")
                return
            }
            handler(row, cell, model)
        }
        
        self.binder.handlers.sectionCellDequeuedCallbacks[section] = dequeueCallback
        
        return self
    }
    
    @discardableResult
    public override func bind<H>(
        headerType: H.Type,
        viewModel: H.ViewModel?,
        updatedBy callbackRef: inout (_ newViewModel: H.ViewModel?) -> Void)
        -> TableViewModelSingleSectionBinder<C, S, M>
        where H : UITableViewHeaderFooterView & ReuseIdentifiable & ViewModelBindable
    {
        super.bind(headerType: headerType, viewModel: viewModel, updatedBy: &callbackRef)
        return self
    }
    
    @discardableResult
    public override func bind(
        headerTitle: String?,
        updatedBy callbackRef: inout (_ newTitle: String?) -> Void)
        -> TableViewModelSingleSectionBinder<C, S, M>
    {
        super.bind(headerTitle: headerTitle, updatedBy: &callbackRef)
        return self
    }
    
    @discardableResult
    public override func bind<F>(
        footerType: F.Type,
        viewModel: F.ViewModel?,
        updatedBy callbackRef: inout (_ newViewModel: F.ViewModel?) -> Void)
        -> TableViewSingleSectionBinder<C, S>
        where F : UITableViewHeaderFooterView & ReuseIdentifiable & ViewModelBindable
    {
        super.bind(footerType: footerType, viewModel: viewModel, updatedBy: &callbackRef)
        return self
    }
    
    @discardableResult
    public override func bind(
        footerTitle: String?,
        updatedBy callbackRef: inout (_ newTitle: String?) -> Void)
        -> TableViewSingleSectionBinder<C, S>
    {
        super.bind(footerTitle: footerTitle, updatedBy: &callbackRef)
        return self
    }
    
    @discardableResult
    override public func onCellDequeue(_ handler: @escaping (_ row: Int, _ dequeuedCell: C) -> Void)
        -> TableViewModelSingleSectionBinder<C, S, M>
    {
        super.onCellDequeue(handler)
        return self
    }
    
    @discardableResult
    override public func onTapped(_ handler: @escaping (_ row: Int, _ tappedCell: C) -> Void)
        -> TableViewModelSingleSectionBinder<C, S, M>
    {
        super.onTapped(handler)
        return self
    }
    
    @discardableResult
    public func dimensions(_ dimensions: SingleSectionModelDimension<S, M>...)
        -> TableViewModelSingleSectionBinder<C, S, M>
    {
        self._dimensions(dimensions)
        return self
    }
}

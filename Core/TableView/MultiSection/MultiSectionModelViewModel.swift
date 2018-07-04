import UIKit

public class TableViewModelViewModelMultiSectionBinder<C: UITableViewCell & ViewModelBindable, S: TableViewSection, M>: BaseTableViewMutliSectionBinder<C, S> {
    private let mapToViewModelFunc: (M) -> C.ViewModel
    
    init(binder: SectionedTableViewBinder<S>, sections: [S], mapToViewModel: @escaping (M) -> C.ViewModel) {
        super.init(binder: binder, sections: sections)
        self.mapToViewModelFunc = mapToViewModel
    }
    
    @discardableResult
    public func onTapped(_ handler: @escaping (_ section: S, _ row: Int, _ tappedCell: C, _ model: M) -> Void) -> TableViewModelViewModelMultiSectionBinder<C, S, M> {
//        for section in self.sections {
//            let bindResult = SingleSectionModelTableViewBindResult<C, S, M>(binder: self.binder, section: section)
//            self.sectionBindResults[section] = bindResult
//            bindResult.onTapped({ row, cell, model in
//                handler(section, row, cell, model)
//            })
//        }
        return self
    }
}

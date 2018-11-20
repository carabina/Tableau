/*
 Forked from tonyarnold's 'Differ' library to add equality checking.
 
 https://github.com/tonyarnold/Differ
 */

struct NestedExtendedDiff: DiffProtocol {
    typealias Index = Int
    
    enum Element {
        case deleteSection(Int)
        case insertSection(Int)
        case updateSection(Int)
        case moveSection(from: Int, to: Int)
        case deleteElement(Int, section: Int)
        case insertElement(Int, section: Int)
        case updateElement(Int, section: Int)
        case moveElement(from: (item: Int, section: Int), to: (item: Int, section: Int))
    }
    
    func index(after i: Int) -> Int {
        return i + 1
    }
    
    var elements: [Element]
    
    init(elements: [Element]) {
        self.elements = elements
    }
}

typealias NestedIdentityChecker<T: Collection> = (T.Element.Element, T.Element.Element) -> Bool where T.Element: Collection
typealias NestedEqualityChecker<T: Collection> = (T.Element.Element, T.Element.Element) -> Bool? where T.Element: Collection

extension Collection where Index == Int, Element: Collection, Element.Index == Int {
    /**
     Creates a diff between the callee and `other` collection. It diffs elements two levels deep (therefore "nested")
     
     - parameters:
     - other: a collection to compare the callee to
     - isSameSection: a closure that determines whether the two section are meant to represent the same item (i.e.
        'identity')
     - isSameElement: a closure that determines whether the two items are meant to represent the same item (i.e.
        'identity')
     - isEqual: a closure that determines whether the two items (deemed to represent the same item) are 'equal' (i.e.
        whether the second instance of the item has any changes from the first that would warrant a cell update)
     - returns: a `NestedDiff` between the calee and `other` collection
    */
    func nestedExtendedDiff(
        to: Self,
        isSameSection: IdentityChecker<Self>,
        isSameElement: NestedIdentityChecker<Self>,
        isEqualElement: NestedEqualityChecker<Self>)
        -> NestedExtendedDiff
    {
        // FIXME: This implementation is a copy paste of NestedDiff with some adjustments.
        let diffTraces = outputDiffPathTraces(to: to, isSame: isSameSection)
        
        let sectionDiff =
            extendedDiff(
                from: Diff(traces: diffTraces),
                other: to,
                isSame: isSameSection,
                isEqual: { _, _ in return false } // TODO: other checks for section updating
                ).map { element -> NestedExtendedDiff.Element in
                    switch element {
                    case let .delete(at):
                        return .deleteSection(at)
                    case let .insert(at):
                        return .insertSection(at)
                    case let .move(from, to):
                        return .moveSection(from: from, to: to)
                    case .update(let at):
                        return .updateSection(at)
                    }
        }
        
        // Diff matching sections (moves, deletions, insertions)
        let filterMatchPoints = { (trace: Trace) -> Bool in
            if case .matchPoint = trace.type() {
                return true
            }
            return false
        }
        
        let sectionMoves =
            sectionDiff.compactMap { diffElement -> (Int, Int)? in
                if case let .moveSection(from, to) = diffElement {
                    return (from, to)
                }
                return nil
                }.flatMap { move -> [NestedExtendedDiff.Element] in
                    return itemOnStartIndex(advancedBy: move.0).extendedDiff(to.itemOnStartIndex(advancedBy: move.1), isSame: isSameElement, isEqual: { _,_ in false })
                        .map { diffElement -> NestedExtendedDiff.Element in
                            switch diffElement {
                            case let .insert(at):
                                return .insertElement(at, section: move.1)
                            case let .delete(at):
                                return .deleteElement(at, section: move.0)
                            case let .move(from, to):
                                return .moveElement(from: (from, move.0), to: (to, move.1))
                            case .update(let at):
                                return .updateElement(at, section: move.0)
                            }
                    }
        }
        
        // offset & section
        
        let matchingSectionTraces = diffTraces
            .filter(filterMatchPoints)
        
        let fromSections = matchingSectionTraces.map {
            itemOnStartIndex(advancedBy: $0.from.x)
        }
        
        let toSections = matchingSectionTraces.map {
            to.itemOnStartIndex(advancedBy: $0.from.y)
        }
        
        let elementDiff = zip(zip(fromSections, toSections), matchingSectionTraces)
            .flatMap { (args) -> [NestedExtendedDiff.Element] in
                let (sections, trace) = args
                return sections.0.extendedDiff(sections.1, isSame: isSameElement, isEqual: isEqualElement).map { diffElement -> NestedExtendedDiff.Element in
                    switch diffElement {
                    case let .delete(at):
                        return .deleteElement(at, section: trace.from.x)
                    case let .insert(at):
                        return .insertElement(at, section: trace.from.y)
                    case let .move(from, to):
                        return .moveElement(from: (from, trace.from.x), to: (to, trace.from.y))
                    case .update(let at):
                        return .updateElement(at, section: trace.from.x) //TODO: not sure if x or y?
                    }
                }
        }
        
        return NestedExtendedDiff(elements: sectionDiff + sectionMoves + elementDiff)
    }
}

extension NestedExtendedDiff.Element: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .deleteElement(row, section):
            return "DE(s:\(section),r:\(row))"
        case let .deleteSection(section):
            return "DS(s:\(section))"
        case let .insertElement(row, section):
            return "IE(s:\(section),r:\(row))"
        case let .insertSection(section):
            return "IS(s:\(section))"
        case let .moveElement(from, to):
            return "ME((s:\(from.section),r:\(from.item)),(s:\(to.section),r:\(to.item)))"
        case let .moveSection(from, to):
            return "MS(from:\(from),to:\(to))"
        case let .updateSection(section):
            return "US(s:\(section))"
        case let .updateElement(row, section):
            return "UE(s:\(section),r:\(row))"
        }
    }
}

extension NestedExtendedDiff: ExpressibleByArrayLiteral {
    
    init(arrayLiteral elements: NestedExtendedDiff.Element...) {
        self.elements = elements
    }
}
import Tableau

/**
 A simple table view cell that just has a center-aligned label. The cell's ViewModel type is just a String, which it
 sets as the text for its center-aligned label. Note that this cell is not created from a Nib, so it does not conform to
 UINibInitable - the binder will take note of this and, when it registers the cell, will register the class instead of a
 Nib file.
 */
final class CenterLabelTableViewCell: UITableViewCell, ViewModelBindable, ReuseIdentifiable {
    typealias ViewModel = String
    
    var viewModel: CenterLabelTableViewCell.ViewModel? {
        didSet {
            self.centerLabel.text = self.viewModel
        }
    }
    
    private let centerLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.addSubview(self.centerLabel)
        self.centerLabel.numberOfLines = 0
        self.centerLabel.textAlignment = .center
        self.centerLabel.font = UIFont.systemFont(ofSize: 12)
        self.centerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[l]-20-|", options: [], metrics: nil, views: ["l": self.centerLabel]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[l]-20-|", options: [], metrics: nil, views: ["l": self.centerLabel]))
    }
}
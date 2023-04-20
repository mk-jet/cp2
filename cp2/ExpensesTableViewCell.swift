import UIKit

class ExpensesTableViewCell: UITableViewCell {

    @IBOutlet weak var designationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        designationLabel.minimumScaleFactor = 0.2
        designationLabel.numberOfLines = 1
        designationLabel.adjustsFontSizeToFitWidth = true
        rateLabel.minimumScaleFactor = 0.2
        rateLabel.numberOfLines = 1
        rateLabel.adjustsFontSizeToFitWidth = true
        
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

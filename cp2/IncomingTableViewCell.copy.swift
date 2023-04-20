//import Foundation
import UIKit

//protocol IncomingTableViewCellDelegate: Any {}

class IncomingTableViewCell: UITableViewCell {
//    var delegate: IncomingTableViewCellDelegate?
    let incomingDate = UILabel()
    let incomingRate = UILabel()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
            
        incomingDate.translatesAutoresizingMaskIntoConstraints = false
        incomingRate.translatesAutoresizingMaskIntoConstraints = false
        incomingDate.font = incomingDate.font.withSize(19)
        incomingRate.font = incomingRate.font.withSize(19)
        incomingRate.textAlignment = .right
        incomingDate.textColor = .black
        incomingRate.textColor = .black
        incomingDate.backgroundColor = .white
        incomingRate.backgroundColor = .white
        
        contentView.backgroundColor = .white
        contentView.addSubview(incomingDate)
        contentView.addSubview(incomingRate)
        
        NSLayoutConstraint.activate([
            incomingDate.heightAnchor.constraint(equalToConstant: 48),
            incomingDate.topAnchor.constraint(equalTo: topAnchor),
            incomingDate.bottomAnchor.constraint(equalTo: bottomAnchor),
            incomingDate.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            incomingDate.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            incomingRate.heightAnchor.constraint(equalToConstant: 48),
            incomingRate.topAnchor.constraint(equalTo: topAnchor),
            incomingRate.bottomAnchor.constraint(equalTo: bottomAnchor),
            incomingRate.leadingAnchor.constraint(equalTo: incomingDate.trailingAnchor),
            incomingRate.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  PlaceScheduleItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/08/2023.
//

import UIKit

class PlaceScheduleItemTableViewCell: UITableViewCell {
    static let nibName = "PlaceScheduleItemTableViewCell"
    static let identifier = "placeScheduleItemTableViewCell"
    
    @IBOutlet weak var contentIdentifierTextLabel: UILabel!
    @IBOutlet weak var contentValueTextLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!
    
    var model: OrbisPlaceWorkingHours! {
        didSet {
            contentIdentifierTextLabel.text = model.dayName
            contentValueTextLabel.text = model.time ?? ""
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

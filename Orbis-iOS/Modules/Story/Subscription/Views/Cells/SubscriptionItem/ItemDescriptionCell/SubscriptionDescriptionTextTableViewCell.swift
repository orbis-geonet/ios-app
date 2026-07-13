//
//  SubscriptionDescriptionTextTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/01/2023.
//

import UIKit

class SubscriptionDescriptionTextTableViewCell: UITableViewCell {
    
    static let identifier = "subscriptionDescriptionText"
    static let nibName = "SubscriptionDescriptionTextTableViewCell"

    @IBOutlet weak var descLabel: UILabel!
    
    var benefitText: String! {
        didSet {
            configureCell()
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
    
    private func configureCell() {
        descLabel.text = benefitText
    }
}

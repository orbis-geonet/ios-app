//
//  NotificationNormalTextTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/04/2021.
//

import UIKit

class NotificationNormalTextTableViewCell: UITableViewCell {
    @IBOutlet weak var notificationTextLabel: UILabel!
    
    var viewModel: NotificationItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let deselectedColor: UIColor = (viewModel.model.seen == true) ? .white : UIColor(named: AppColors.appOffWhite2.rawValue)!
        self.contentView.backgroundColor = deselectedColor
        // Configure the view for the selected state
    }
    
    func setSelectedUI() {
        self.contentView.backgroundColor = UIColor(named: AppColors.appSelectionBlue.rawValue)!
    }
    
    func updateViewContent() {
        notificationTextLabel.attributedText = viewModel.attributedMessage
    }
    
}

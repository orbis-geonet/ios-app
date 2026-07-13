//
//  ReceivedMessageTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import UIKit

class ReceivedMessageTableViewCell: UITableViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var viewModel: ChatMessageViewModel! {
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

        // Configure the view for the selected state
    }
    
    func updateViewContent() {
        dayLabel.isHidden = !viewModel.shouldShowDay
        dayLabel.text = viewModel.dateString
        messageLabel.text = viewModel.messageContent
        timeLabel.text = viewModel.timeString
    }

}

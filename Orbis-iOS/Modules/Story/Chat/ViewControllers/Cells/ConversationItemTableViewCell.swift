//
//  ConversationItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import UIKit


class ConversationItemTableViewCell: UITableViewCell {
    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var unreadIndicatorView: RoundedView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var viewModel: ConversationListItemViewModel! {
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
        nameLabel.text = viewModel.userName
        messageLabel.text = viewModel.messageContent
        unreadIndicatorView.isHidden = viewModel.isRead
        messageLabel.font = viewModel.isRead ? UIFont(name: "Roboto-Regular", size: 14.toCGFloat.relativeToIphone8Width()) : UIFont(name: "Roboto-Medium", size: 14.toCGFloat.relativeToIphone8Width())
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.userPropicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.userPropicLink
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }

}

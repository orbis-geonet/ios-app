//
//  NormalTextWithUserTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/04/2021.
//

import UIKit
import SDWebImage


class NormalTextWithUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userProPicContainer: RoundedView!
    @IBOutlet weak var userPicView: UIImageView!
    
    @IBOutlet weak var messageLabel: UILabel!
    
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
        messageLabel.attributedText = viewModel.attributedMessage
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.userProPicLink.isEmpty else {
            userPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.userProPicLink
        
        userPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
}

//
//  NotificationWithActionTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/04/2021.
//

import UIKit
import SDWebImage

class NotificationWithActionTableViewCell: UITableViewCell {

    @IBOutlet weak var userProPicContainer: RoundedView!
    @IBOutlet weak var userPicView: UIImageView!
    @IBOutlet weak var acceptBtn: UIButton!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBAction func acceptTapped(_ sender: Any) {
        guard let user = viewModel.model.fromUser else { return }
        onAcceptFollowRequest?(user)
    }
    
    var onAcceptFollowRequest: ((OrbisUser) -> Void)?
    
    var viewModel: NotificationItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateStaticTexts()
        addLanguageUpdateObserver()
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let deselectedColor: UIColor = (viewModel.model.seen == true) ? .white : UIColor(named: AppColors.appOffWhite2.rawValue)!
        self.contentView.backgroundColor = deselectedColor
        // Configure the view for the selected state
    }
    
    func updateStaticTexts() {
        acceptBtn.setTitle(AppStrings.Notification.acceptAction, for: .normal)
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

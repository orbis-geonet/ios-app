//
//  ProfileTableHeaderTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/04/2021.
//

import UIKit
import SDWebImage

protocol ProfileViewModelDataSource: AnyObject {
    func connectInstagramTapped()
    func followUnfollowTapped(view: UIView)
    func getProfileModel() -> ProfileDetailViewModel
    func selfProPicTapped(view: UIView)
    func settingsTapped()
    func groupCountTapped()
    func followingCountTapped()
    func followerCountTapped()
}

class ProfileTableHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var groupsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingsLabel: UILabel!
    
    @IBOutlet weak var userProPicContainerView: RoundedView!
    @IBOutlet weak var userProPicView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var groupCountLabel: UILabel!
    @IBOutlet weak var follwersCountLabel: UILabel!
    @IBOutlet weak var followingsCountLabel: UILabel!
    
    @IBOutlet weak var headerActionButtonContainer: RoundedView!
    @IBOutlet weak var headerActionBtn: UIButton!
    @IBOutlet weak var connectedIconView: UIImageView!
    @IBOutlet weak var followingCountStackView: UIStackView!
    @IBOutlet weak var followerCountStackView: UIStackView!
    @IBOutlet weak var groupCountStackView: UIStackView!
    
    @IBAction func settingTapped(_ sender: Any) {
        dataSource?.settingsTapped()
    }
    @IBAction func headerActionTapped(_ sender: Any) {
        dataSource?.connectInstagramTapped()
    }
    @IBAction func proPicTapped(_ sender: Any) {
        guard let viewModel = dataSource?.getProfileModel(), viewModel.isViewingSelf else { return }
        dataSource?.selfProPicTapped(view: userProPicContainerView)
    }
    
    weak var dataSource: ProfileViewModelDataSource?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureStackViewActions()
        updateStaticTexts()
        addLanguageUpdateObserver()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }
    
    func updateStaticTexts() {
        groupsLabel.text = AppStrings.Group.groups
        followersLabel.text = AppStrings.Profile.followers
        followingsLabel.text = AppStrings.Profile.following
    }
    
    func configureStackViewActions() {
        let groupCountTapGesture = UITapGestureRecognizer(target: self, action: #selector(groupCountTapped(_:)))
        let followerCountTapGesture = UITapGestureRecognizer(target: self, action: #selector(followerCountTapped(_:)))
        let followingCountTapGesture = UITapGestureRecognizer(target: self, action: #selector(followingCountTapped(_:)))
        
        groupCountStackView.isUserInteractionEnabled = true
        followerCountStackView.isUserInteractionEnabled = true
        followingCountStackView.isUserInteractionEnabled = true
        
        groupCountStackView.addGestureRecognizer(groupCountTapGesture)
        followerCountStackView.addGestureRecognizer(followerCountTapGesture)
        followingCountStackView.addGestureRecognizer(followingCountTapGesture)
    }
    
    @objc private func groupCountTapped(_ gesture: UITapGestureRecognizer) {
        dataSource?.groupCountTapped()
    }
    
    @objc private func followerCountTapped(_ gesture: UITapGestureRecognizer) {
        dataSource?.followerCountTapped()
    }
    
    @objc private func followingCountTapped(_ gesture: UITapGestureRecognizer) {
        dataSource?.followingCountTapped()
    }
    
    func updateViewContent() {
        guard let viewModel = dataSource?.getProfileModel() else { return }
        userNameLabel.text = viewModel.userFullName
        groupCountLabel.text = viewModel.userGroupCount
        follwersCountLabel.text = viewModel.userFollowerCount
        followingsCountLabel.text = viewModel.userFollowingCount
        updateActionButtionUI(hasConneted: viewModel.hasConnectedInstagram)
        updateProfilePic(viewModel: viewModel)
    }
    
    private func updateActionButtionUI(hasConneted: Bool) {
        headerActionButtonContainer.backgroundColor = hasConneted ? .white : UIColor(named: AppColors.appBlack.rawValue)!
        headerActionBtn.setTitleColor(hasConneted ? UIColor(named: AppColors.appBlack.rawValue)! : .white, for: .normal)
        headerActionButtonContainer.borderColor = UIColor(named: AppColors.appBlack.rawValue)!
        headerActionButtonContainer.borderWidth = hasConneted ? 1 : 0
        connectedIconView.isHidden = !hasConneted
        let title = hasConneted ? AppStrings.Profile.instagramConnected : AppStrings.Profile.connectInstagram
        headerActionBtn.setTitle(title, for: .normal)
    }
    
    private func updateProfilePic(viewModel: ProfileDetailViewModel) {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.userProPicLink.isEmpty else {
            userProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.userProPicLink
        
        userProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
}

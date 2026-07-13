//
//  OtherUserProfileHeaderTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import UIKit
import SDWebImage


class OtherUserProfileHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var groupsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingsLabel: UILabel!
    
    @IBOutlet weak var userProPicContainerView: RoundedView!
    @IBOutlet weak var userProPicView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var groupCountLabel: UILabel!
    @IBOutlet weak var follwersCountLabel: UILabel!
    @IBOutlet weak var followingsCountLabel: UILabel!
    @IBOutlet weak var groupCountStackView: UIStackView!
    @IBOutlet weak var followerCountStackView: UIStackView!
    @IBOutlet weak var followingCountStackView: UIStackView!
    
    @IBOutlet weak var headerActionButtonContainer: RoundedView!
    @IBOutlet weak var headerActionBtn: UIButton!
    @IBOutlet weak var loaderView: UIView!
    
    @IBAction func moreTapped(_ sender: Any) {
        onOtherProfileMoreTapped?()
    }
    @IBAction func headerActionTapped(_ sender: Any) {
        performFollowUnfollowTap()
    }
    
    weak var dataSource: ProfileViewModelDataSource?
    var onOtherProfileMoreTapped: (() -> Void)?
    
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
    
    private func performFollowUnfollowTap() {
        guard let viewModel = dataSource?.getProfileModel(), !viewModel.isViewingSelf else { return }
        dataSource?.followUnfollowTapped(view: headerActionButtonContainer)
//        guard let viewModel2 = dataSource?.getProfileModel() else { return }
//        updateActionButtionUI(hasFollowed: viewModel2.hasFollowed)
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
        updateActionButtionUI(hasFollowed: viewModel.hasFollowed, viewModel: viewModel)
        updateProfilePic(viewModel: viewModel)
    }
    
    private func updateActionButtionUI(hasFollowed: Bool, viewModel: ProfileDetailViewModel) {
        if viewModel.isAccountPrivate {
            let unfollowedColor: UIColor = viewModel.isRequestPending ? .white : UIColor(named: AppColors.appBlack.rawValue)!
            let unfollowedBorderColor: UIColor = viewModel.isRequestPending ? UIColor(named: AppColors.appBlack.rawValue)! : .white
            headerActionButtonContainer.backgroundColor = hasFollowed ? .white : unfollowedColor
            headerActionBtn.setTitleColor(hasFollowed ? UIColor(named: AppColors.appBlack.rawValue)! : unfollowedBorderColor, for: .normal)
            headerActionButtonContainer.borderColor = hasFollowed ? UIColor(named: AppColors.appBlack.rawValue)! : unfollowedBorderColor
            let unfollowedBorderWidth: CGFloat = viewModel.isRequestPending ? 1 : 0
            headerActionButtonContainer.borderWidth = hasFollowed ? 1 : unfollowedBorderWidth
            let unfollowedText = viewModel.isRequestPending ? AppStrings.Profile.requested : AppStrings.Profile.follow
            let title = hasFollowed ? AppStrings.Profile.following : unfollowedText
            headerActionBtn.setTitle(title, for: .normal)
        }
        else {
            headerActionButtonContainer.backgroundColor = hasFollowed ? .white : UIColor(named: AppColors.appBlack.rawValue)!
            headerActionBtn.setTitleColor(hasFollowed ? UIColor(named: AppColors.appBlack.rawValue)! : .white, for: .normal)
            headerActionButtonContainer.borderColor = UIColor(named: AppColors.appBlack.rawValue)!
            headerActionButtonContainer.borderWidth = hasFollowed ? 1 : 0
            let title = hasFollowed ? AppStrings.Profile.following : AppStrings.Profile.follow
            headerActionBtn.setTitle(title, for: .normal)
        }
        
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

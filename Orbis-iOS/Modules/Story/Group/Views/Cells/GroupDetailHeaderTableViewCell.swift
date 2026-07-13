//
//  GroupDetailHeaderTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import UIKit
import SDWebImage


class GroupDetailHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var placesLabel: UILabel!
    @IBOutlet weak var membersLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var groupProPicContainerView: RoundedView!
    @IBOutlet weak var groupProPicView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupPlacesCountLabel: UILabel!
    @IBOutlet weak var groupMembersCountLabel: UILabel!
    @IBOutlet weak var groupStatusIconView: UIImageView!
    @IBOutlet weak var groupDescriptionLabel: OrbisExpandableLabel!
    @IBOutlet weak var descriptionLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var moreBtnIconView: UIImageView!
    
    @IBOutlet weak var placesCountStackView: UIStackView!
    @IBOutlet weak var membersCountStackView: UIStackView!

    @IBOutlet weak var subscriptionButtonStackView: UIStackView!
    @IBOutlet weak var btnEditSubscription: UIButton!
    @IBOutlet weak var btnActivity: UIButton!
    @IBOutlet weak var btnCreateSubscription: UIButton!
    @IBOutlet weak var btnSubscription: UIButton!
    @IBOutlet weak var btnUpdateSubscription: UIButton!

    @IBOutlet weak var editSubscriptionBtnHolder: RoundedView!
    @IBOutlet weak var subscriptionActivityBtnHolder: RoundedView!
    @IBOutlet weak var createSubscriptionBtnHolder: RoundedView!
    @IBOutlet weak var subscriptionBtnHolder: RoundedView!
    @IBOutlet weak var updateSubscriptionBtnHolder: RoundedView!
    
    
    @IBAction func groupMoreBtnTapped(_ sender: Any) {
        onGroupMoreBtnTapped?(self, moreBtnIconView)
    }

    @IBAction func editSubscriptionBtnTapped(_ sender: Any) {
        onEditSubscriptionTapped?()
    }

    @IBAction func activityBtnTapped(_ sender: Any) {
        onActivityTapped?()
    }

    @IBAction func createSubscriptionBtnTapped(_ sender: Any) {
        onCreateSubscriptionTapped?()
    }

    @IBAction func subscriptionBtnTapped(_ sender: Any) {
        onSubscriptionTapped?()
    }

    @IBAction func updateSubscriptionBtnTapped(_ sender: Any) {
        onUpdateSubscriptionTapped?()
    }
    
    var onMembersCountTapped: (() -> Void)?
    var onPlacesCountTapped: (() -> Void)?
    var onGroupMoreBtnTapped: ((UITableViewCell, UIView) -> Void)?

    var onEditSubscriptionTapped: (() -> Void)?
    var onActivityTapped: (() -> Void)?
    var onCreateSubscriptionTapped: (() -> Void)?
    var onSubscriptionTapped: (() -> Void)?
    var onUpdateSubscriptionTapped: (() -> Void)?
    
    var viewModel: GroupDetailHeaderViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addStackGestures()
        descriptionLabelWidthConstraint.constant = UIScreen.main.bounds.width - CGFloat(30).relativeToIphone8Width()
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
        placesLabel.text = AppStrings.Group.places
        statusLabel.text = AppStrings.Group.status
        membersLabel.text = AppStrings.Group.members
        
        btnSubscription.setTitle(AppStrings.Subscription.GroupDetailsButtonsText.subscription, for: .normal)
        btnEditSubscription.setTitle(AppStrings.Subscription.GroupDetailsButtonsText.editSubscription, for: .normal)
        btnActivity.setTitle(AppStrings.Subscription.GroupDetailsButtonsText.subscriptionActivity, for: .normal)
        btnCreateSubscription.setTitle(AppStrings.Subscription.GroupDetailsButtonsText.createSubscription, for: .normal)
        btnUpdateSubscription.setTitle(AppStrings.Subscription.GroupDetailsButtonsText.subscription, for: .normal)
    }
    
    private func addStackGestures() {
        membersCountStackView.isUserInteractionEnabled = true
        let membersCountTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.membersCountTapped(_:)))
        membersCountStackView.addGestureRecognizer(membersCountTapGesture)
        
        placesCountStackView.isUserInteractionEnabled = true
        let placesCountTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.placesCountTapped(_:)))
        placesCountStackView.addGestureRecognizer(placesCountTapGesture)
    }
    
    @objc private func membersCountTapped(_ gesture: UITapGestureRecognizer) {
        onMembersCountTapped?()
    }
    
    @objc private func placesCountTapped(_ gesture: UITapGestureRecognizer) {
        onPlacesCountTapped?()
    }
    
    func updateViewContent() {
        groupProPicContainerView.borderColor = viewModel.baseColor
        groupNameLabel.text = viewModel.name
        groupStatusIconView.image = viewModel.indicatorImage
        groupDescriptionLabel.text = viewModel.description
        groupDescriptionLabel.isHidden = viewModel.description.isEmpty
        groupPlacesCountLabel.text = viewModel.placesCountString
        groupMembersCountLabel.text = viewModel.membersCountString
        updateGroupProfilePic()
        updateSubscriptionButtons()
    }
    
    private func updateGroupProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.propicLink.isEmpty else {
            groupProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        groupProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .groupPictures, sizeModifier: .fourHundred)
    }

    private func updateSubscriptionButtons() {
        editSubscriptionBtnHolder.isHidden = true
        subscriptionActivityBtnHolder.isHidden = true
        createSubscriptionBtnHolder.isHidden = true
        subscriptionBtnHolder.isHidden = true
        updateSubscriptionBtnHolder.isHidden = true
        subscriptionButtonStackView.isHidden = true
        
        guard UserSessionManager.shared.isUserInBrazil else { return } // Remove this once subscription is set to available everywhere
        
        if viewModel.isNotInGroup {
            subscriptionButtonStackView.isHidden = true
        }
        else {
            if (viewModel.isMainAdmin) {
                subscriptionButtonStackView.isHidden = false
                if viewModel.hasSubscription {
                    editSubscriptionBtnHolder.isHidden = false
                    subscriptionActivityBtnHolder.isHidden = false
                } else {
                    createSubscriptionBtnHolder.isHidden = false
                }
            } else {
                if(viewModel.memberShouldSeeSubscription) {
                    subscriptionButtonStackView.isHidden = false
                    if(viewModel.isSubscriber) {
                        updateSubscriptionBtnHolder.isHidden = false
                    } else {
                        subscriptionBtnHolder.isHidden = false
                    }
                }
            }
        }

    }
}

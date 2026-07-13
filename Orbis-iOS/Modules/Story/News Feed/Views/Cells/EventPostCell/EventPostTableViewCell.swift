//
//  EventPostTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit
import SDWebImage

class EventPostTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkedImageView: UIImageView!
    
    @IBOutlet weak var user1ProPicView: UIImageView!
    @IBOutlet weak var user2ProPicView: UIImageView!
    @IBOutlet weak var user3ProPicView: UIImageView!
    @IBOutlet weak var user3ProPicContainer: RoundedView!
    @IBOutlet weak var user2ProPicContainer: RoundedView!
    @IBOutlet weak var user1ProPicContainer: RoundedView!
    @IBOutlet weak var confirmedUsersStackView: UIStackView!
    @IBOutlet weak var confirmedTextLabel: UILabel!
    
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var confirmBtnView: RoundedView!
    @IBOutlet weak var moreBtnView: UIView!
    
    @IBAction func moreTapped(_ sender: Any) {
        actionDelegate?.didTapMore(onCell: self, tappedView: moreBtnView, post: viewModel.model)
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        actionDelegate?.didTapEvenAttend(onCell: self, post: viewModel.model)
    }
    
    weak var actionDelegate: PostCellActionDelegate?
    
    var viewModel: EventPostCellViewModel! {
        didSet {
            handleViewModelActions()
            viewModel.fetchConfirmedUsers()
            updateViewContent()
        }
    }
    weak var imageFullSizeDeleage: FeedImageFullViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(linkedImageTapped(_:)))
        linkedImageView.isUserInteractionEnabled = true
        linkedImageView.addGestureRecognizer(imageTapGesture)
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
        confirmLabel.text = AppStrings.Events.attend
        confirmedTextLabel.text = AppStrings.Events.confirmed + ":"
    }
    
    @objc private func linkedImageTapped(_ sender: UIImageView) {
        imageFullSizeDeleage?.didTapImage(at: 0, inCell: self)
    }
    
    func handleViewModelActions() {
        viewModel.onConfirmedUsersFetched = {
            [weak self] in
            self?.handleConfirmedUsers()
        }
    }
    
    func updateViewContent() {
        titleLabel.text = viewModel.eventTitle
        dateLabel.text = viewModel.eventDate
        timeLabel.text = viewModel.eventTime
        descriptionLabel.text = viewModel.eventDescription
        descriptionLabel.isHidden = viewModel.eventDescription.isEmpty
        linkedImageView.isHidden = viewModel.eventImageLink.isEmpty
        updateLinkedImage()
        updateSelfAttendingUI()
        handleConfirmedUsers()
    }
    
    private func updateSelfAttendingUI() {
        confirmLabel.text = viewModel.isAttending ? AppStrings.Events.going : AppStrings.Events.willGo
        confirmLabel.textColor = viewModel.isAttending ? UIColor(named: AppColors.appBlack.rawValue) : UIColor.white
        confirmBtnView.backgroundColor = viewModel.isAttending ? UIColor(named: AppColors.appPinkishGray.rawValue) : UIColor(named: AppColors.appBlack.rawValue)
    }
    
    private func updateUserProPic(for user: OrbisUser, imageView: UIImageView, containerView: RoundedView) {
        containerView.borderColor = user.color
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard let proPicLink = user.proPicLink, !proPicLink.isEmpty else {
            imageView.image = placeholderImage
            return
        }
        imageView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func updateLinkedImage() {
        guard !viewModel.eventImageLink.isEmpty else {
            return
        }
        let imageLink = viewModel.eventImageLink
        if imageLink.isNotUrlLink {
            let ref = imageLink.getFirebaseReference(storage: .eventImages, imageSizeResolution: .sixEighty)
            linkedImageView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed])
        }
        else {
            linkedImageView.sd_setImage(with: URL(string: imageLink)!, placeholderImage: nil)
        }
    }
    
    private func handleConfirmedUsers() {
        guard viewModel.users.count > 0 else {
            confirmedUsersStackView.isHidden = true
            confirmedTextLabel.alpha = 0
            return
        }
        confirmedUsersStackView.isHidden = false
        confirmedTextLabel.alpha = 1
        switch viewModel.users.count {
        case 1:
            user1ProPicContainer.isHidden = false
            user2ProPicContainer.isHidden = true
            user3ProPicContainer.isHidden = true
            let user1 = viewModel.users[0]
            updateUserProPic(for: user1, imageView: user1ProPicView, containerView: user1ProPicContainer)
            break
        case 2:
            user1ProPicContainer.isHidden = false
            user2ProPicContainer.isHidden = false
            user3ProPicContainer.isHidden = true
            let user1 = viewModel.users[0]
            let user2 = viewModel.users[1]
            updateUserProPic(for: user1, imageView: user1ProPicView, containerView: user1ProPicContainer)
            updateUserProPic(for: user2, imageView: user2ProPicView, containerView: user2ProPicContainer)
            break
        default:
            user1ProPicContainer.isHidden = false
            user2ProPicContainer.isHidden = false
            user3ProPicContainer.isHidden = false
            let user1 = viewModel.users[0]
            let user2 = viewModel.users[1]
            let user3 = viewModel.users[2]
            updateUserProPic(for: user1, imageView: user1ProPicView, containerView: user1ProPicContainer)
            updateUserProPic(for: user2, imageView: user2ProPicView, containerView: user2ProPicContainer)
            updateUserProPic(for: user3, imageView: user3ProPicView, containerView: user3ProPicContainer)
            break
        }
    }
}

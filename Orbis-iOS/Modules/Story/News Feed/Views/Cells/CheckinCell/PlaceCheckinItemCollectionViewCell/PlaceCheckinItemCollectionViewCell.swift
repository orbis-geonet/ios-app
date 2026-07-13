//
//  PlaceCheckinItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 15/06/2021.
//

import UIKit

class PlaceCheckinItemCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var postOwnerProPicView: UIImageView!
    @IBOutlet weak var postOwnerProPicContainer: RoundedView!
    @IBOutlet weak var postOwnerNameLabel: UILabel!
    @IBOutlet weak var postedDateLabel: UILabel!
    @IBOutlet weak var postedLocationLabel: UILabel!
    @IBOutlet weak var locationStackView: UIStackView!
    
    @IBOutlet weak var checkinUserNameLabel: UILabel!
    @IBOutlet weak var checkinUserProPicView: UIImageView!
    @IBOutlet weak var checkinPlaceLabel: UILabel!
    @IBOutlet weak var likeIconView: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentIconView: UIImageView!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    @IBOutlet weak var moreBtnView: UIView!
    
    @IBOutlet weak var likeStackView: UIStackView!
    @IBOutlet weak var commentStackView: UIStackView!
    @IBOutlet weak var checkinUserStackView: UIStackView!
    @IBOutlet weak var checkinTextLabel: UILabel!
    
    @IBAction func moreTapped(_ sender: Any) {
        actionDelegate?.didTapMore(onCell: self, tappedView: moreBtnView, post: viewModel.model)
    }
    
    var viewModel: CheckingPostItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    weak var actionDelegate: PostCellActionDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCommentStack(_:)))
        commentStackView.isUserInteractionEnabled = true
        commentStackView.addGestureRecognizer(commentTapGesture)
        
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLikeStack(_:)))
        likeIconView.isUserInteractionEnabled = true
        likeIconView.addGestureRecognizer(likeTapGesture)
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLocationStack(_:)))
        locationStackView.isUserInteractionEnabled = true
        locationStackView.addGestureRecognizer(locationTapGesture)
        
        let locationNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLocationStack(_:)))
        checkinPlaceLabel.isUserInteractionEnabled = true
        checkinPlaceLabel.addGestureRecognizer(locationNameTapGesture)
        
        let postOwnerNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        let postOwnerPicTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        postOwnerNameLabel.isUserInteractionEnabled = true
        postOwnerNameLabel.addGestureRecognizer(postOwnerNameTapGesture)
        postOwnerProPicContainer.isUserInteractionEnabled = true
        postOwnerProPicContainer.addGestureRecognizer(postOwnerPicTapGesture)
        
        let userStackTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCheckinUser(_:)))
        checkinUserStackView.isUserInteractionEnabled = true
        checkinUserStackView.addGestureRecognizer(userStackTapGesture)
        
        updateStaticText()
        addLanguageUpdateObserver()
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticText()
    }
    
    private func updateStaticText() {
        checkinTextLabel.text = AppStrings.Checkin.checkin
    }
    
    @objc private func didTapCheckinUser(_ gesture: UIGestureRecognizer) {
        guard let user = viewModel.model.user else { return }
        actionDelegate?.didTapUserStack(onCell: self, user: user)
    }
    
    @objc private func didTapPostOwner(_ gesture: UIGestureRecognizer) {
        guard let group = viewModel.model.group else {
            if let user = viewModel.model.user {
                actionDelegate?.didTapUserStack(onCell: self, user: user)
            }
            return
        }
        actionDelegate?.didTapGroupName(onCell: self, group: group)
    }
    
    @objc private func didTapCommentStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapCommentStack(onCell: self, post: viewModel.model)
    }
    
    @objc private func didTapLikeStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapLikeStack(onCell: self, post: viewModel.model)
    }
    
    @objc private func didTapLocationStack(_ gesture: UIGestureRecognizer) {
        guard let place = viewModel.model.place else { return }
        actionDelegate?.didTapLocationStack(onCell: self, place: place)
    }
    
    func updateViewContent() {
        postOwnerProPicContainer.borderColor = viewModel.postUserBaseColor
        postOwnerNameLabel.text = viewModel.postUserFullName
        checkinUserNameLabel.text = viewModel.checkinUserName
        checkinPlaceLabel.text = viewModel.checkinPlace
        postedDateLabel.text = viewModel.datePostedString
        postedLocationLabel.text = viewModel.locationString
        locationStackView.isHidden = viewModel.locationString.isEmpty
        let likeColor = viewModel.likeIconColor
        likeIconView.tintColor = likeColor
        likeCountLabel.textColor = likeColor
        likeCountLabel.text = viewModel.likeCountString
        commentCountLabel.text = viewModel.commentCountString
        updatePosterProfilePic()
        updateCheckinUserProfilePic()
    }
    
    private func updatePosterProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.postUserProPicLink.isEmpty else {
            postOwnerProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.postUserProPicLink
        postOwnerProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .groupPictures, sizeModifier: .fourHundred)
    }
    
    private func updateCheckinUserProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.checkinUserProPic.isEmpty else {
            checkinUserProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.checkinUserProPic
        checkinUserProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }

}

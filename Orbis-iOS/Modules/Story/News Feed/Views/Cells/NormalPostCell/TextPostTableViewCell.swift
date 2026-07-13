//
//  TextPostTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit
import SDWebImage


protocol PostCellActionDelegate: AnyObject {
    func didTapMore(onCell: UITableViewCell, tappedView: UIView, post: OrbisFeedPost)
    func didTapMore(onCell: UICollectionViewCell, tappedView: UIView, post: OrbisFeedPost)
    func didTapCommentStack(onCell cell: UITableViewCell, post: OrbisFeedPost)
    func didTapCommentStack(onCell cell: UICollectionViewCell, post: OrbisFeedPost)
    func didTapLikeStack(onCell cell: UITableViewCell, post: OrbisFeedPost)
    func didTapLikeStack(onCell cell: UICollectionViewCell, post: OrbisFeedPost)
    func didTapLocationStack(onCell cell: UITableViewCell, place: OrbisPlace)
    func didTapLocationStack(onCell cell: UICollectionViewCell, place: OrbisPlace)
    func didTapGroupName(onCell cell: UITableViewCell, group: Group)
    func didTapGroupName(onCell cell: UICollectionViewCell, group: Group)
    func didTapUserStack(onCell cell: UITableViewCell, user: OrbisUser)
    func didTapUserStack(onCell cell: UICollectionViewCell, user: OrbisUser)
    func didTapViewMore(onCell: UITableViewCell, post: OrbisFeedPost, maxLines: Int)
    func didTapViewMore(onCell: UICollectionViewCell, post: OrbisFeedPost, maxLines: Int)
    func didTapEvenAttend(onCell: UITableViewCell, post: OrbisFeedPost)
}

class TextPostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postOwnerProPicView: UIImageView!
    @IBOutlet weak var postOwnerProPicContainer: RoundedView!
    @IBOutlet weak var postOwnerNameLabel: UILabel!
    @IBOutlet weak var postedDateLabel: UILabel!
    @IBOutlet weak var postedLocationLabel: UILabel!

    @IBOutlet weak var descriptionLabel: OrbisActiveLabel!

    @IBOutlet weak var likeIconView: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentIconView: UIImageView!
    @IBOutlet weak var commentCountLabel: UILabel!

    @IBOutlet weak var subPosterNameLabel: UILabel!
    @IBOutlet weak var subPosterImageView: UIImageView!
    @IBOutlet weak var locationStackView: UIStackView!
    
    @IBOutlet weak var bottomUserInfoView: UIStackView!
    @IBOutlet weak var bottomStackViewSpacer: UIView!
    @IBOutlet weak var moreBtnView: UIView!
    @IBOutlet weak var likeStackView: UIStackView!
    @IBOutlet weak var commentStackView: UIStackView!
    
    @IBOutlet weak var richTextContentStack: UIStackView!
    @IBOutlet weak var externalUrlImageView: UIImageView!
    @IBOutlet weak var externalUrlDomainLabel: UILabel!
    @IBOutlet weak var externalUrlTitleLabel: UILabel!
    @IBOutlet weak var externalUrlDescriptionLabel: UILabel!
    @IBOutlet weak var viewMoreBtn: UIButton!
    
    
    @IBAction func moreTapped(_ sender: Any) {
        actionDelegate?.didTapMore(onCell: self, tappedView: moreBtnView, post: viewModel.model)
    }
    @IBAction func expandTextTapped(_ sender: Any) {
        var newPost = viewModel.model!
        newPost.isDescriptionExpanded = !newPost.isDescriptionExpanded
        actionDelegate?.didTapViewMore(onCell: self, post: newPost, maxLines: descriptionLabel.calculateMaxLines())
    }
    
    var viewModel: TextPostCellViewModel! {
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
        
        let richContentTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapRichContent(_:)))
        richTextContentStack.isUserInteractionEnabled = true
        richTextContentStack.addGestureRecognizer(richContentTapGesture)
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLocationStack(_:)))
        locationStackView.isUserInteractionEnabled = true
        locationStackView.addGestureRecognizer(locationTapGesture)
        
        let postOwnerNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        let postOwnerPicTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        postOwnerNameLabel.isUserInteractionEnabled = true
        postOwnerNameLabel.addGestureRecognizer(postOwnerNameTapGesture)
        postOwnerProPicContainer.isUserInteractionEnabled = true
        postOwnerProPicContainer.addGestureRecognizer(postOwnerPicTapGesture)
        
        let postUserStackTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostUser(_:)))
        bottomUserInfoView.isUserInteractionEnabled = true
        bottomUserInfoView.addGestureRecognizer(postUserStackTapGesture)
    }
    
    @objc private func didTapPostUser(_ gesture: UIGestureRecognizer) {
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
    
    @objc private func didTapLocationStack(_ gesture: UIGestureRecognizer) {
        guard let place = viewModel.model.place else { return }
        actionDelegate?.didTapLocationStack(onCell: self, place: place)
    }
    
    @objc private func didTapCommentStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapCommentStack(onCell: self, post: viewModel.model)
    }
    
    @objc private func didTapLikeStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapLikeStack(onCell: self, post: viewModel.model)
    }
    
    @objc private func didTapRichContent(_ gesture: UIGestureRecognizer) {
        guard let urlString = viewModel.richContent?.originalUrl, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateViewContent() {
        postOwnerProPicContainer.borderColor = viewModel.posterBaseColor
        postOwnerNameLabel.text = viewModel.posterFullName
        postedDateLabel.text = viewModel.datePostedString
        postedLocationLabel.text = viewModel.locationString
        descriptionLabel.text = viewModel.description
        descriptionLabel.isHidden = viewModel.description.isEmpty
        fillRichTextContent()
        let likeColor = viewModel.likeIconColor
        likeIconView.tintColor = likeColor
        likeCountLabel.textColor = likeColor
        likeCountLabel.text = viewModel.likeCountString
        commentCountLabel.text = viewModel.commentCountString
        bottomUserInfoView.isHidden = !viewModel.shouldShowBottomUser
        bottomStackViewSpacer.isHidden = viewModel.shouldShowBottomUser
        locationStackView.isHidden = viewModel.locationString.isEmpty
        fillSubPosterDetail()
        updateProfilePic()
        descriptionLabel.numberOfLines = viewModel.numberOfLines
        viewMoreBtn.isHidden = !(descriptionLabel.calculateMaxLines() > AppValues.postTextMaxLines)
        updateTextMoreBtnText()
    }
    
    private func updateTextMoreBtnText() {
        let title = (descriptionLabel.numberOfLines == 0) ? AppStrings.viewLess : AppStrings.viewMore
        viewMoreBtn.setTitle(title, for: .normal)
    }
    
    private func fillRichTextContent() {
        richTextContentStack.isHidden = !viewModel.hasRichTextContent
        if var imageUrl = viewModel.richContent?.imageUrl, !imageUrl.isEmpty {
            self.externalUrlImageView.isHidden = false
            if !imageUrl.contains("http") && !imageUrl.contains("www.") {
                if let originalUrl = viewModel.richContent?.originalUrl, !originalUrl.isEmpty {
                    imageUrl = originalUrl + "/\(imageUrl)"
                }
            }
            imageUrl = imageUrl.toProperURLString
            externalUrlImageView.sd_setImage(with: URL(string: imageUrl)) {
                [weak self] image, error, _ , _ in
                if image == nil || error != nil {
                    self?.externalUrlImageView.isHidden = true
                }
            }
        }
        else {
            self.externalUrlImageView.isHidden = true
        }
        externalUrlTitleLabel.text = viewModel.richContent?.title ?? ""
        externalUrlDomainLabel.text = viewModel.richContent?.canonicalUrl?.uppercased() ?? ""
        externalUrlDescriptionLabel.text = viewModel.richContent?.description ?? ""
    }
    
    private func fillSubPosterDetail() {
        subPosterNameLabel.text = viewModel.subPosterFullName
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.subPosterProPicLink.isEmpty else {
            subPosterImageView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.subPosterProPicLink
        subPosterImageView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.posterProPicLink.isEmpty else {
            postOwnerProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.posterProPicLink
        postOwnerProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: viewModel.shouldShowBottomUser ? .groupPictures : .profilePictures, sizeModifier: .fourHundred)
    }
    
}

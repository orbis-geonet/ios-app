//
//  CommentItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import UIKit


class CommentItemTableViewCell: UITableViewCell {
    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timePostedLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var likeIndicatorView: UIImageView!
    
    
    @IBAction func replyTapped(_ sender: Any) {
        onReplyCommentTapped?(self)
    }
    @IBAction func likeTapped(_ sender: Any) {
        onLikeCommentTapped?(self)
    }
    
    var viewModel: PostCommentItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    var onLikeCommentTapped: ((UITableViewCell) -> Void)?
    var onReplyCommentTapped: ((UITableViewCell) -> Void)?
    var onCommentUserTapped: ((OrbisUser) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let proPicTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCommentUser(_:)))
        let userNameTapGesture = UITapGestureRecognizer(target: self, action:  #selector(didTapCommentUser(_:)))
        proPicContainerView.isUserInteractionEnabled = true
        proPicContainerView.addGestureRecognizer(proPicTapGesture)
        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(userNameTapGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @objc private func didTapCommentUser(_ gesture: UIGestureRecognizer) {
        guard let user = viewModel.model.user else { return }
        onCommentUserTapped?(user)
    }

    private func updateViewContent() {
        userNameLabel.text = viewModel.userName
        timePostedLabel.text = viewModel.datePosted
        commentLabel.text = viewModel.comment
        likeCountLabel.text = viewModel.likesCount
        likeIndicatorView.tintColor = viewModel.likeIconColor
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.userProPicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.userProPicLink
        
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
}

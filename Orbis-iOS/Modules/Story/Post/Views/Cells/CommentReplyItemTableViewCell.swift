//
//  CommentReplyItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import UIKit


class CommentReplyItemTableViewCell: UITableViewCell {

    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var likeIconView: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    
    @IBAction func replyTapped(_ sender: Any) {
        onReplyCommentTapped?(self)
    }
    @IBAction func likeTapped(_ sender: Any) {
        onLikeCommentTapped?(self)
    }
    
    var viewModel: CommentReplyViewModel! {
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
        proPicContainerView.isUserInteractionEnabled = true
        proPicContainerView.addGestureRecognizer(proPicTapGesture)
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
        commentLabel.text = ""
        commentLabel.attributedText = viewModel.commentAttributed
        commentLabel.layoutIfNeeded()
        self.layoutIfNeeded()
        likeCountLabel.text = viewModel.likesCount
        likeIconView.tintColor = viewModel.likeIconColor
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

//
//  CommentWithRepliesTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import UIKit
import SDWebImage


class CommentWithRepliesTableViewCell: UITableViewCell {

    @IBOutlet weak var repliesLabel: UILabel!
    @IBOutlet weak var commentContentView: UIView!
    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timePostedLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var likeIndicatorView: UIImageView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadMoreStackView: UIStackView!
    @IBOutlet weak var loadMoreBtn: UIButton!
    
    @IBOutlet weak var repliesTableView: UITableView!
    
    @IBAction func replyTapped(_ sender: Any) {
        onReplyCommentTapped?(self)
    }
    @IBAction func loadMoreTapped(_ sender: Any) {
        onLoadMoreTapped?(self)
    }
    @IBAction func likeTapped(_ sender: Any) {
        onLikeCommentTapped?(self)
    }
    
    var onLikeCommentTapped: ((UITableViewCell) -> Void)?
    var onReplyCommentTapped: ((UITableViewCell) -> Void)?
    var onLoadMoreTapped: ((UITableViewCell) -> Void)?
    var onReplyTapped: ((String, PostComment) -> Void)?
    var onLikeReplyTapped: ((PostComment) -> Void)?
    
    var viewModel: PostCommentItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    var onCommentUserTapped: ((OrbisUser) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let proPicTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCommentUser(_:)))
        let userNameTapGesture = UITapGestureRecognizer(target: self, action:  #selector(didTapCommentUser(_:)))
        proPicContainerView.isUserInteractionEnabled = true
        proPicContainerView.addGestureRecognizer(proPicTapGesture)
        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(userNameTapGesture)
        setupTableView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    deinit {
        repliesTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    @objc private func didTapCommentUser(_ gesture: UIGestureRecognizer) {
        guard let user = viewModel.model.user else { return }
        onCommentUserTapped?(user)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.repliesTableView && keyPath == "contentSize" {
                guard viewModel != nil else {
                    return
                }
                let newHeight = obj.contentSize.height
                print("Height for \(self.viewModel.userName) comment with \(self.viewModel.repliesCount) replies = \(newHeight)")
                
                self.tableViewHeightConstraint.constant = newHeight
                self.repliesTableView.layoutIfNeeded()
                self.layoutIfNeeded()
//                DispatchQueue.main.async {
//                    [weak self] in
//                    self?.repliesTableView.layoutIfNeeded()
//                    debugPrint("Cell layout of \(self?.viewModel.userName ?? "") is being changed....from tableView Height change")
//                    self?.layoutIfNeeded()
//                }
                
            }
        }
    }
    
    func setupTableView() {
        repliesTableView.register(UINib(nibName: "CommentReplyItemTableViewCell", bundle: nil), forCellReuseIdentifier: "commentReplyCell")
        repliesTableView.delegate = self
        repliesTableView.dataSource = self
        repliesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        repliesTableView.addGestureRecognizer(longTapGesture)
    }
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        guard let user = UserSessionManager.shared.currentUser else { return }
        guard (user.userKey == viewModel.model.user?.userKey || user.userKey == viewModel.model.post?.user?.userKey) else { return }
        if sender.state == .began {
            let touchPoint = sender.location(in: repliesTableView)
            if let indexPath = repliesTableView.indexPathForRow(at: touchPoint) {
                let model = viewModel.replies[indexPath.row]
                onReplyTapped?(model.commentKey, viewModel.model)
            }
        }
    }

    private func updateViewContent() {
        loadMoreStackView.isHidden = !viewModel.hasMore
        userNameLabel.text = viewModel.userName
        timePostedLabel.text = viewModel.datePosted
        commentLabel.text = viewModel.comment
        commentLabel.layoutIfNeeded()
        self.layoutIfNeeded()
        likeCountLabel.text = viewModel.likesCount
        likeIndicatorView.tintColor = viewModel.likeIconColor
        updateProfilePic()
        repliesTableView.reloadData()
//        DispatchQueue.main.async {
//            [weak self] in
//            self?.commentLabel.layoutIfNeeded()
//            debugPrint("Cell layout of \(self?.viewModel.userName ?? "") is being changed....from comment label height change")
//            self?.layoutIfNeeded()
//        }
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

extension CommentWithRepliesTableViewCell: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.repliesCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.replies[indexPath.row]
        let commentCell = tableView.dequeueReusableCell(withIdentifier: "commentReplyCell") as! CommentReplyItemTableViewCell
        commentCell.viewModel = CommentReplyViewModel(reply: model)
        commentCell.onReplyCommentTapped = {
            [weak self] cell in
            guard let self = self else { return }
            self.onReplyCommentTapped?(self)
        }
        commentCell.onLikeCommentTapped = {
            [weak self] cell in
            guard let self = self, let cell = cell as? CommentReplyItemTableViewCell else { return }
            self.onLikeReplyTapped?(cell.viewModel.model)
        }
        commentCell.onCommentUserTapped = {
            [weak self] user in
            self?.onCommentUserTapped?(user)
        }
        return commentCell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
}

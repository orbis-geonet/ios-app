//
//  CommentsViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import UIKit
import GrowingTextView
import IQKeyboardManager

class CommentsViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewContainer: UIView!
    @IBOutlet weak var inputTextView: GrowingTextView!
    @IBOutlet weak var userProPicView: UIImageView!
    
    var viewModel: PostCommentsViewModel!
    var selectedCommentCell: UITableViewCell?
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        guard !inputTextView.text.isEmpty && !inputTextView.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        self.view.endEditing(true)
        performCommentAction()
    }
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
    override func isAutoHandleKeyboardEnabled() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if commentsTableView.frame.contains(panGesturePoint) {
            return commentsTableView.contentOffset.y <= 0
        }
        return true
    }
    
    private var isIQKeyboardEnabled: Bool = false
    
    struct TableViewConfig {
        static let replyCellEstimatedHeight = 120.toCGFloat.relativeToIphone8Width()
        static let commentCellEstimatedHeight = 150.toCGFloat.relativeToIphone8Width()
    }
    
    var isLoadingComments = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        handleViewModelActions()
        addObservers()
        resetCommentsData()
        loadComments()
        updateSelfUserInfo()
        updateStaticTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.performWithoutAnimation {
            commentsTableView.beginUpdates()
            commentsTableView.endUpdates()
        }
        self.isIQKeyboardEnabled = IQKeyboardManager.shared().isEnabled
        IQKeyboardManager.shared().isEnabled = false
        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared().isEnabled = self.isIQKeyboardEnabled
        self.view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Post.Comments.commentTitle
        inputTextView.placeholder = AppStrings.Post.Comments.commentPlaceholder
    }
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: commentsTableView)
            if let indexPath = commentsTableView.indexPathForRow(at: touchPoint) {
                let model = viewModel.getComment(at: indexPath.row)
                guard let user = UserSessionManager.shared.currentUser else { return }
                guard (user.userKey == model.user?.userKey || user.userKey == model.post?.user?.userKey) else { return }
                showDeleteCommentView(forModel: model)
            }
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardNotification(_ notification: NSNotification) {
        if let userInfo = notification.userInfo, let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let isShowing = notification.name == UIResponder.keyboardWillShowNotification
            inputViewBottomConstraint.constant = isShowing ? keyboardFrame.height : 0
            UIView.animateWithDuration(0, delay: 0) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    private func updateSelfUserInfo() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.userProPicLink.isEmpty else {
            userProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.userProPicLink
        
        userProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func setupTableView() {
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        commentsTableView.addGestureRecognizer(longTapGesture)
        
        inputTextView.delegate = self
    }

    private func handleViewModelActions() {
        viewModel.onCommentsFetchError = {
            [weak self] error in
            self?.isLoadingComments = false
            self?.handleError(error: error)
            self?.hideOrbisLoader()
        }
        viewModel.onCommentsFetched = {
            [weak self] in
            self?.isLoadingComments = false
            self?.hideOrbisLoader()
            self?.commentsTableView.reloadData()
        }
        viewModel.onCommentsFetchedCompletePagination = {
            [weak self] in
            self?.isLoadingComments = false
            self?.hideOrbisLoader()
            self?.commentsTableView.reloadData()
            guard let commentCount = self?.viewModel.totalCommentCount else { return }
            NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: commentCount)
        }
        viewModel.onCommentsUpdated = {
            [weak self] index in
            DispatchQueue.main.async { [weak self] in
                self?.commentsTableView.reloadData()
            }
        }
        
        viewModel.onNewCommentAdded = {
            [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.commentsTableView.reloadData()
                self?.commentsTableView.scrollToLastItem(animated: false)
            }
        }
        
        viewModel.onNewCommentRemoved = {
            [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.commentsTableView.reloadData()
            }
        }
        
        viewModel.onNewCommentAddFailure = {
            [weak self] error in
            self?.handleError(error: error)
            DispatchQueue.main.async { [weak self] in
                self?.commentsTableView.reloadData()
            }
        }
    }
    
    private func resetCommentsData() {
        viewModel.initializePagination()
        self.commentsTableView.reloadData()
    }
    
    private func loadComments() {
        self.showOrbisLoader()
        isLoadingComments = true
        viewModel.loadPostComments()
    }
    
    private func loadMoreComments() {
        self.showOrbisLoader()
        isLoadingComments = true
        viewModel.loadMorePostComments()
    }
    
    private func performCommentAction() {
        if let selectedCommentCell = self.selectedCommentCell, let index = commentsTableView.indexPath(for: selectedCommentCell)?.row {
            viewModel.postCommentReply(text: inputTextView.text, commentKey: viewModel.getComment(at: index).commentKey)
            self.handleReplyCommentAction(onCell: selectedCommentCell)
        }
        else {
            viewModel.postComment(text: inputTextView.text)
        }
        inputTextView.text = ""
    }
    
    private func gotoUserProfileView(withUser user: OrbisUser) {
        if user.deleted == true  {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        let isViewingSelf = (user.userKey == UserSessionManager.shared.currentUser?.userKey)
        let profileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        profileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: isViewingSelf)
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func handleLoadMoreReplies(onCell cell: UITableViewCell) {
//        guard let indexpath = commentsTableView.indexPath(for: cell) else { return }
//        viewModel.loadMoreReplies(forIndex: indexpath.row)
//        commentsTableView.beginUpdates()
//        commentsTableView.reloadRows(at: [indexpath], with: .automatic)
//        commentsTableView.endUpdates()
    }
    
    func handleLikeCommentAction(onCell cell: UITableViewCell) {
        if let commentWithReplyCell = cell as? CommentWithRepliesTableViewCell {
            viewModel.likeUnlikeComment(comment: commentWithReplyCell.viewModel.model)
        }
        else if let commentWithoutReplyCell = cell as? CommentItemTableViewCell {
            viewModel.likeUnlikeComment(comment: commentWithoutReplyCell.viewModel.model)
        }
    }
    
    private func handleReplyCommentAction(onCell cell: UITableViewCell) {
        if let commentWithReplyCell = self.selectedCommentCell as? CommentWithRepliesTableViewCell {
            commentWithReplyCell.commentContentView.backgroundColor = .white
            if selectedCommentCell == cell {
                selectedCommentCell = nil
                return
            }
        }
        else if let commentWithoutReplyCell = self.selectedCommentCell as? CommentItemTableViewCell {
            commentWithoutReplyCell.contentView.backgroundColor = .white
            if selectedCommentCell == cell {
                selectedCommentCell = nil
                return
            }
        }
        
        if let commentWithReplyCell = cell as? CommentWithRepliesTableViewCell {
            self.selectedCommentCell = commentWithReplyCell
            commentWithReplyCell.commentContentView.backgroundColor = UIColor(named: AppColors.appBlueGray.rawValue)?.withAlphaComponent(0.10)
        }
        else if let commentWithoutReplyCell = cell as? CommentItemTableViewCell {
            self.selectedCommentCell = commentWithoutReplyCell
            commentWithoutReplyCell.contentView.backgroundColor = UIColor(named: AppColors.appBlueGray.rawValue)?.withAlphaComponent(0.10)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getComment(at: indexPath.row)
        if model.hasReplies {
            let commentCell = tableView.dequeueReusableCell(withIdentifier: "commentWithRepliesItemCell") as! CommentWithRepliesTableViewCell
            commentCell.viewModel = PostCommentItemViewModel(comment: model)
            commentCell.onLoadMoreTapped = {
                [weak self] cell in
                self?.handleLoadMoreReplies(onCell: cell)
            }
            commentCell.onReplyCommentTapped = {
                [weak self] cell in
                self?.handleReplyCommentAction(onCell: cell)
            }
            commentCell.onLikeCommentTapped = {
                [weak self] cell in
                self?.handleLikeCommentAction(onCell: cell)
            }
            commentCell.onLikeReplyTapped = {
                [weak self] comment in
                self?.viewModel.likeUnlikeComment(comment: comment)
            }
            commentCell.onReplyTapped = {
                [weak self] replyKey, commentModel in
                self?.showDeleteCommentReplyView(replyKey: replyKey, commentModel: commentModel)
            }
            commentCell.onCommentUserTapped = {
                [weak self] user in
                self?.gotoUserProfileView(withUser: user)
            }
            commentCell.layoutIfNeeded()
            if let selectedCell = self.selectedCommentCell as? CommentWithRepliesTableViewCell, selectedCell.viewModel.model.commentKey == model.commentKey {
                commentCell.commentContentView.backgroundColor = UIColor(named: AppColors.appBlueGray.rawValue)?.withAlphaComponent(0.10)
            }
            else {
                if let cell = self.selectedCommentCell as? CommentItemTableViewCell, cell.viewModel.model.commentKey == model.commentKey {
                    commentCell.commentContentView.backgroundColor = UIColor(named: AppColors.appBlueGray.rawValue)?.withAlphaComponent(0.10)
                }
                commentCell.commentContentView.backgroundColor = .white
            }
            return commentCell
        }
        else {
            let commentCell = tableView.dequeueReusableCell(withIdentifier: "commentItemCell") as! CommentItemTableViewCell
            commentCell.viewModel = PostCommentItemViewModel(comment: model)
            commentCell.onReplyCommentTapped = {
                [weak self] cell in
                self?.handleReplyCommentAction(onCell: cell)
            }
            commentCell.onLikeCommentTapped = {
                [weak self] cell in
                self?.handleLikeCommentAction(onCell: cell)
            }
            commentCell.onCommentUserTapped = {
                [weak self] user in
                self?.gotoUserProfileView(withUser: user)
            }
            if let selectedCell = self.selectedCommentCell as? CommentItemTableViewCell, selectedCell.viewModel.model.commentKey == model.commentKey {
                commentCell.contentView.backgroundColor = UIColor(named: AppColors.appBlueGray.rawValue)?.withAlphaComponent(0.10)
            }
            else {
                commentCell.contentView.backgroundColor = .white
            }
            return commentCell
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = viewModel.getComment(at: indexPath.row)
        let numberOfReplies = model.replies?.count ?? 0
        return TableViewConfig.commentCellEstimatedHeight + (numberOfReplies.toCGFloat * TableViewConfig.replyCellEstimatedHeight)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.inputAccessoryView?.frame.height ?? 70.toCGFloat.relativeToIphone8Height()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoadingComments && !viewModel.hasItemsLastPageReached {
            self.loadMoreComments()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    private func showDeleteCommentView(forModel model: PostComment) {
        let deleteVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "deleteCommentVC") as! CommentDeletePopupViewController
        deleteVC.modalPresentationStyle = .overFullScreen
        deleteVC.shouldDismissViewOnTapOutside = true
        deleteVC.commentModel = model
        deleteVC.onDeleteTapped = {
            [weak self] commentKey in
            self?.viewModel.deleteComment(key: commentKey)
        }
        deleteVC.onDismiss = {
            // later do some UI changes if required
        }
        self.present(deleteVC, animated: false, completion: nil)
    }
    
    private func showDeleteCommentReplyView(replyKey: String, commentModel: PostComment) {
        let deleteVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "deleteCommentVC") as! CommentDeletePopupViewController
        deleteVC.modalPresentationStyle = .overFullScreen
        deleteVC.shouldDismissViewOnTapOutside = true
        deleteVC.commentModel = commentModel.replies!.first(where: {$0.commentKey == replyKey})
        deleteVC.onDeleteTapped = {
            [weak self] commentKey in
            self?.viewModel.deleteCommentReply(key: commentKey, fromComment: commentModel.commentKey)
        }
        deleteVC.onDismiss = {
            // later do some UI changes if required
        }
        self.present(deleteVC, animated: false, completion: nil)
    }
}

extension CommentsViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard let _ = UserSessionManager.shared.currentUser else {
            if let parentVC = self.presentingViewController {
                if UserSessionManager.shared.hasLoginOnboardingBeenShown {
                    let authView = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authMainVC") as! AuthMainViewController
                    authView.defaultSelectionIndex = 0
                    if let parentNavVC = parentVC as? UINavigationController {
                        parentNavVC.pushViewController(authView, animated: false)
                    }
                    else {
                        parentVC.navigationController?.pushViewController(authView, animated: false)
                    }
                }
                else {
                    UserSessionManager.shared.setLoginOnboardingShown()
                    let authOptionPickerVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authOptionPickerVC") as! AuthOptionPickerViewController
                    if let parentNavVC = parentVC as? UINavigationController {
                        parentNavVC.pushViewController(authOptionPickerVC, animated: false)
                    }
                    else {
                        parentVC.navigationController?.pushViewController(authOptionPickerVC, animated: false)
                    }
                }
                self.dismiss(animated: true)
            }
            return false
        }
        return true
    }
}

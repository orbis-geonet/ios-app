//
//  PostDetailsViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/08/2021.
//

import UIKit
import GrowingTextView
import IQKeyboardManager

class PostDetailsViewController: OrbisLocalizableViewController {

    @IBOutlet weak var postDetailsTableView: UITableView!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewContainer: UIView!
    @IBOutlet weak var inputTextView: GrowingTextView!
    @IBOutlet weak var userProPicView: UIImageView!
    
    var postDetailViewModel: PostDetailViewModel!
    var commentsViewModel: PostCommentsViewModel!
    var selectedCommentCell: UITableViewCell?
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func sendTapped(_ sender: Any) {
        guard !inputTextView.text.isEmpty && !inputTextView.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        self.view.endEditing(true)
        performCommentAction()
    }
    
    private var isIQKeyboardEnabled: Bool = false
    
    struct TableViewConfig {
        static let replyCellEstimatedHeight = 120.toCGFloat.relativeToIphone8Width()
        static let commentCellEstimatedHeight = 150.toCGFloat.relativeToIphone8Width()
    }
    
    struct FeedCellIdentifier {
        static let textPostCell = "textPostCell"
        static let imagePostCell = "imagePostCell"
        static let checkinPostCell = "checkinPostCell"
        static let audioPostCell = "audioPostCell"
        static let videoPostCell = "videoPostCell"
        static let eventPostCell = "eventPostCell"
    }
    
    var isLoadingComments = false
    weak var cellActionView: PostCellActionView?
    var currentPlayigAudio: AudioPostTableViewCell?
    var currentPlayingVideo: VideoPostTableViewCell?
    
    var imageFullSizeViewer: OrbisImageGalleryViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        commentsViewModel = PostCommentsViewModel(post: postDetailViewModel.model)
        handleViewModelActions()
        addObservers()
        syncPostDetails()
        resetCommentsData()
        loadComments()
        updateSelfUserInfo()
        updateStaticTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.performWithoutAnimation {
            postDetailsTableView.beginUpdates()
            postDetailsTableView.endUpdates()
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
        inputTextView.placeholder = AppStrings.Post.Comments.commentPlaceholder
    }
    
    private func updateSelfUserInfo() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !commentsViewModel.userProPicLink.isEmpty else {
            userProPicView.image = placeholderImage
            return
        }
        let proPicLink = commentsViewModel.userProPicLink
        
        userProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        postDetailsTableView.addGestureRecognizer(longTapGesture)
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
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: postDetailsTableView)
            if let indexPath = postDetailsTableView.indexPathForRow(at: touchPoint) {
                guard indexPath.section == 1 else { return }
                let model = commentsViewModel.getComment(at: indexPath.row)
                guard let user = UserSessionManager.shared.currentUser else { return }
                guard (user.userKey == model.user?.userKey || user.userKey == model.post?.user?.userKey) else { return }
                showDeleteCommentView(forModel: model)
            }
        }
    }
    
    private func setupTableView() {
        postDetailsTableView.register(UINib(nibName: "ImagePostTableViewCell", bundle: nil), forCellReuseIdentifier: FeedCellIdentifier.imagePostCell)
        postDetailsTableView.register(UINib(nibName: "TextPostTableViewCell", bundle: nil), forCellReuseIdentifier: FeedCellIdentifier.textPostCell)
        postDetailsTableView.register(UINib(nibName: "AudioPostTableViewCell", bundle: nil), forCellReuseIdentifier: FeedCellIdentifier.audioPostCell)
        postDetailsTableView.register(UINib(nibName: "VideoPostTableViewCell", bundle: nil), forCellReuseIdentifier: FeedCellIdentifier.videoPostCell)
        postDetailsTableView.register(UINib(nibName: "CheckinPostTableViewCell", bundle: nil), forCellReuseIdentifier: FeedCellIdentifier.checkinPostCell)
        postDetailsTableView.register(UINib(nibName: "EventPostTableViewCell", bundle: nil), forCellReuseIdentifier: FeedCellIdentifier.eventPostCell)
        
        postDetailsTableView.delegate = self
        postDetailsTableView.dataSource = self
        inputTextView.delegate = self
        inputViewContainer.isHidden = true
    }
    
    private func syncPostDetails() {
        self.showOrbisLoader()
        postDetailViewModel.syncPostDetailsWithServer()
    }

    private func handleViewModelActions() {
        postDetailViewModel.onPostDetailSyncError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.hideOrbisLoader()
        }
        postDetailViewModel.onPostDetailSyncSuccess = {
            [weak self] in
            self?.hideOrbisLoader()
            self?.inputViewContainer.isHidden = self?.postDetailViewModel.model.postType == .eventPost
            self?.postDetailsTableView.reloadData()
        }
        postDetailViewModel.onPostUpdated = {
            [weak self] in
            self?.postDetailsTableView.reloadData()
        }
        
        commentsViewModel.onCommentsFetchError = {
            [weak self] error in
            self?.isLoadingComments = false
            self?.handleError(error: error)
            self?.hideOrbisLoader()
        }
        commentsViewModel.onCommentsFetched = {
            [weak self] in
            self?.isLoadingComments = false
            self?.hideOrbisLoader()
            self?.postDetailsTableView.reloadData()
        }
        commentsViewModel.onCommentsFetchedCompletePagination = {
            [weak self] in
            self?.isLoadingComments = false
            self?.hideOrbisLoader()
            self?.postDetailsTableView.reloadData()
        }
        
        commentsViewModel.onNewCommentAdded = {
            [weak self] in
            var newPost = self!.postDetailViewModel.model!
            newPost.incrementComment()
            self?.postDetailViewModel.updatePost(newPost: newPost)
            DispatchQueue.main.async { [weak self] in
                self?.postDetailsTableView.reloadData()
                self?.postDetailsTableView.scrollToLastItem(animated: false)
            }
        }
        
        commentsViewModel.onNewCommentRemoved = {
            [weak self] in
            var newPost = self!.postDetailViewModel.model!
            newPost.decrementComment()
            self?.postDetailViewModel.updatePost(newPost: newPost)
            DispatchQueue.main.async { [weak self] in
                self?.postDetailsTableView.reloadData()
            }
        }
        
        commentsViewModel.onNewCommentAddFailure = {
            [weak self] error in
            self?.handleError(error: error)
            DispatchQueue.main.async { [weak self] in
                self?.postDetailsTableView.reloadData()
            }
        }
        
        commentsViewModel.onCommentsUpdated = {
            [weak self] index in
            DispatchQueue.main.async { [weak self] in
                self?.postDetailsTableView.reloadData()
            }
        }
        
        postDetailViewModel.onPostUpdated = {
            [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.postDetailsTableView.reloadData()
            }
        }
    }
    
    private func resetCommentsData() {
        commentsViewModel.initializePagination()
        self.postDetailsTableView.reloadData()
    }
    
    private func loadComments() {
        self.showOrbisLoader()
        isLoadingComments = true
        commentsViewModel.loadPostComments()
    }
    
    private func loadMoreComments() {
        self.showOrbisLoader()
        isLoadingComments = true
        commentsViewModel.loadMorePostComments()
    }
    
    private func performCommentAction() {
        if let selectedCommentCell = self.selectedCommentCell, let index = postDetailsTableView.indexPath(for: selectedCommentCell)?.row {
            commentsViewModel.postCommentReply(text: inputTextView.text, commentKey: commentsViewModel.getComment(at: index).commentKey)
            self.handleReplyCommentAction(onCell: selectedCommentCell)
        }
        else {
            commentsViewModel.postComment(text: inputTextView.text)
        }
        inputTextView.text = ""
    }
}

extension PostDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func handleLoadMoreReplies(onCell cell: UITableViewCell) {
//        guard let indexpath = postDetailsTableView.indexPath(for: cell) else { return }
//        commentsViewModel.loadMoreReplies(forIndex: indexpath.row)
//        postDetailsTableView.beginUpdates()
//        postDetailsTableView.reloadRows(at: [indexpath], with: .automatic)
//        postDetailsTableView.endUpdates()
    }
    
    func handleLikeCommentAction(onCell cell: UITableViewCell) {
        if let commentWithReplyCell = cell as? CommentWithRepliesTableViewCell {
            commentsViewModel.likeUnlikeComment(comment: commentWithReplyCell.viewModel.model)
        }
        else if let commentWithoutReplyCell = cell as? CommentItemTableViewCell {
            commentsViewModel.likeUnlikeComment(comment: commentWithoutReplyCell.viewModel.model)
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (postDetailViewModel.model.postType == .unknown) ? 0 : 1
        }
        guard commentsViewModel != nil else { return 0}
        return commentsViewModel.count
    }
    
    private func getPostTableViewCell(ofType type: OrbisPostType, tableView: UITableView) -> UITableViewCell {
        let model = postDetailViewModel.model
        switch type {
        case .textPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedCellIdentifier.textPostCell) as! TextPostTableViewCell
            let cellViewModel = TextPostCellViewModel(data: model!)
            cell.viewModel = cellViewModel
            cell.actionDelegate = self
            if cellViewModel.isPendingPost {
                cell.addLoadingOverlay()
            }
            else {
                cell.removeExistingLoadingOverlay()
            }
            return cell
        case .imagePost:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedCellIdentifier.imagePostCell) as! ImagePostTableViewCell
            let cellViewModel = ImagePostCellViewModel(data: model!, pageIndex: postDetailViewModel.sliderPageIndex)
            cell.viewModel = cellViewModel
            cell.actionDelegate = self
            cell.imageFullSizeDeleage = self
            cell.viewModel.onPageIndexChanged = {
                [weak self] page in
                self?.postDetailViewModel.updateSliderPageIndex(value: page)
            }
            if cellViewModel.isPendingPost {
                cell.addLoadingOverlay()
            }
            else {
                cell.removeExistingLoadingOverlay()
            }
            cell.layoutIfNeeded()
            return cell
        case .audioPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedCellIdentifier.audioPostCell) as! AudioPostTableViewCell
            let cellViewModel = AudioPostCellViewModel(data: model!)
            cell.viewModel = cellViewModel
            cell.actionDelegate = self
            cell.onAudioStartPlaying = {
                [weak self] playerCell in
                self?.currentPlayingVideo?.player?.pause()
                if self?.currentPlayigAudio != playerCell {
                    self?.currentPlayigAudio?.pausePlayer()
                    self?.currentPlayigAudio = playerCell
                }
            }
            if cellViewModel.isPendingPost {
                cell.addLoadingOverlay()
            }
            else {
                cell.removeExistingLoadingOverlay()
            }
            return cell
        case .checkinPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedCellIdentifier.checkinPostCell) as! CheckinPostTableViewCell
            let cellViewModel = CheckingPostViewModel(checkinPosts: [model!], pageIndex: postDetailViewModel.sliderPageIndex)
            cell.viewModel = cellViewModel
            cell.actionDelegate = self
            cell.viewModel.onPageIndexChanged = {
                [weak self] page in
                self?.postDetailViewModel.updateSliderPageIndex(value: page)
            }
            if cellViewModel.isPendingPost {
                cell.addLoadingOverlay()
            }
            else {
                cell.removeExistingLoadingOverlay()
            }
            cell.layoutIfNeeded()
            return cell
        case .eventPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedCellIdentifier.eventPostCell) as! EventPostTableViewCell
            let cellViewModel = EventPostCellViewModel(data: model!)
            cell.actionDelegate = self
            cell.imageFullSizeDeleage = self
            cell.viewModel = cellViewModel
            if cellViewModel.isPendingPost {
                cell.addLoadingOverlay()
            }
            else {
                cell.removeExistingLoadingOverlay()
            }
            return cell
        case .videoPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedCellIdentifier.videoPostCell) as! VideoPostTableViewCell
            let cellViewModel = VideoPostCellViewModel(data: model!)
            cell.viewModel = cellViewModel
            cell.actionDelegate = self
            cell.onVideoStartedPlaying = {
                [weak self] playerCell in
                self?.currentPlayigAudio?.pausePlayer()
                if self?.currentPlayingVideo != playerCell {
                    self?.currentPlayingVideo?.player?.pause()
                    self?.currentPlayingVideo = playerCell
                }
                
            }
            if cellViewModel.isPendingPost {
                cell.addLoadingOverlay()
            }
            else {
                cell.removeExistingLoadingOverlay()
            }
            return cell
        case .unknown:
            return UITableViewCell(frame: .zero)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let type = postDetailViewModel.model.postType
            guard type != .unknown else {
                return UITableViewCell(frame: .zero)
            }
            return getPostTableViewCell(ofType: type, tableView: tableView)
        }
        let model = commentsViewModel.getComment(at: indexPath.row)
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
                self?.commentsViewModel.likeUnlikeComment(comment: comment)
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
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        }
        let model = commentsViewModel.getComment(at: indexPath.row)
        let numberOfReplies = model.replies?.count ?? 0
        return TableViewConfig.commentCellEstimatedHeight + (numberOfReplies.toCGFloat * TableViewConfig.replyCellEstimatedHeight)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return self.inputAccessoryView?.frame.height ?? 70.toCGFloat.relativeToIphone8Height()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        let loadMoreIndex = commentsViewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoadingComments && !commentsViewModel.hasItemsLastPageReached {
            self.loadMoreComments()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            guard let model = postDetailViewModel.model else { return }
            guard model.postType == .eventPost else { return }
            showEventDetailsView(event: model)
            return
        }
    }
    
    private func showEventDetailsView(event: OrbisFeedPost) {
        let eventsDetailVC = UIStoryboard.getViewController(inStoryboard: "Events", identifier: "eventsDetailVC") as! EventDetailsViewController
        eventsDetailVC.viewModel = EventDetailsViewModel(event: event)
        let navVC = OrbisNavigationController(rootViewController: eventsDetailVC)
        navVC.modalPresentationStyle = .overFullScreen
        eventsDetailVC.onPostUpdated = {
            [weak self] post in
            self?.postDetailViewModel.updatePost(newPost: post)
        }
        self.presentPanModal(navVC)
    }
    
    private func showDeleteCommentView(forModel model: PostComment) {
        let deleteVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "deleteCommentVC") as! CommentDeletePopupViewController
        deleteVC.modalPresentationStyle = .overFullScreen
        deleteVC.shouldDismissViewOnTapOutside = true
        deleteVC.commentModel = model
        deleteVC.onDeleteTapped = {
            [weak self] commentKey in
            self?.commentsViewModel.deleteComment(key: commentKey)
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
            self?.commentsViewModel.deleteCommentReply(key: commentKey, fromComment: commentModel.commentKey)
        }
        deleteVC.onDismiss = {
            // later do some UI changes if required
        }
        self.present(deleteVC, animated: false, completion: nil)
    }
}

extension PostDetailsViewController: PostCellActionDelegate {
    
    func didTapEvenAttend(onCell: UITableViewCell, post: OrbisFeedPost) {
        self.showOrbisLoader(disableUserInteraction: true)
        postDetailViewModel.attendCancelAttendEvent(event: post) { data, err in
            if let error = err {
                self.handleError(error: error)
            }
            self.hideOrbisLoader()
        }
    }
    
    func didTapViewMore(onCell: UITableViewCell, post: OrbisFeedPost, maxLines: Int) {
        guard let index = self.postDetailsTableView.indexPath(for: onCell) else { return }
        postDetailViewModel.replaceExpandedPost(expandedPost: post)
        postDetailsTableView.beginUpdates()
        let point = onCell.convert(CGPoint.zero, to: postDetailsTableView)
        if let indexPath = postDetailsTableView.indexPathForRow(at: point) as IndexPath? {
            DispatchQueue.main.async { [weak self] in
                var animationSpeed: Double = 0.5
                let diff = maxLines - AppValues.postTextMaxLines
                if diff > 1 {
                    animationSpeed = 0.5 * 0.21 * Double(diff)
                    if animationSpeed > 1.5 {
                        animationSpeed = 1.5
                    }
                    if animationSpeed < 0.5 {
                        animationSpeed = 0.5
                    }
                }
                UIView.animate(withDuration: animationSpeed) { [weak self] in
                    self?.postDetailsTableView.scrollToRow(at: indexPath, at: .top, animated: false)
                }
            }
        }
        postDetailsTableView.reloadRows(at: [index], with: .none)
        postDetailsTableView.endUpdates()
    }
    
    func didTapViewMore(onCell: UICollectionViewCell, post: OrbisFeedPost, maxLines: Int) {
    }
    
    private func performLikeUnlike(onPost post: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        postDetailViewModel.likeUnlikePost(post: post)
    }
    
    func didTapLikeStack(onCell cell: UITableViewCell, post: OrbisFeedPost) {
        performLikeUnlike(onPost: post)
    }
    
    func didTapLikeStack(onCell cell: UICollectionViewCell, post: OrbisFeedPost) {
        performLikeUnlike(onPost: post)
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
    
    func didTapUserStack(onCell cell: UITableViewCell, user: OrbisUser) {
        gotoUserProfileView(withUser: user)
    }
    
    func didTapUserStack(onCell cell: UICollectionViewCell, user: OrbisUser) {
        gotoUserProfileView(withUser: user)
    }
    
    func didTapGroupName(onCell cell: UITableViewCell, group: Group) {
        gotoGroupDetailView(withModel: group)
    }
    
    func didTapGroupName(onCell cell: UICollectionViewCell, group: Group) {
        gotoGroupDetailView(withModel: group)
    }
    
    private func gotoGroupDetailView(withModel model: Group) {
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: model)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    func didTapLocationStack(onCell cell: UITableViewCell, place: OrbisPlace) {
        gotoPlaceDetailView(place: place)
    }
    
    func didTapLocationStack(onCell cell: UICollectionViewCell, place: OrbisPlace) {
        gotoPlaceDetailView(place: place)
    }
    
    private func openCommentView(forPost post: OrbisFeedPost) {
//        let postCommentsVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "postCommentsVC") as! CommentsViewController
//        postCommentsVC.modalPresentationStyle = .overFullScreen
//        postCommentsVC.viewModel = PostCommentsViewModel(postId: post.postKey!)
//        presentPanModal(postCommentsVC)
    }
    
    func didTapCommentStack(onCell cell: UITableViewCell, post: OrbisFeedPost) {
        openCommentView(forPost: post)
    }
    
    func didTapCommentStack(onCell cell: UICollectionViewCell, post: OrbisFeedPost) {
        openCommentView(forPost: post)
    }
    
    
    private func removeCellMoreActionView() {
        cellActionView?.removeFromSuperview()
        cellActionView = nil
    }
    
    private func showPostCellActionView<T>(inLocation point: CGPoint, item: T?, tappedViewFrame: CGRect) {
        guard let post = item else {
            return
        }
        removeCellMoreActionView()
        let cellPostActionView = PostCellActionView(frame: self.view.bounds)
        cellPostActionView.deleteActionView.isHidden = !((item as? OrbisFeedPost)?.isSelfPostedOrSuperAdmin ?? false)
        cellPostActionView.actionBtnContainer.alpha = 0
        self.view.addSubview(cellPostActionView)
        cellPostActionView.translatesAutoresizingMaskIntoConstraints = false
        cellPostActionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        cellPostActionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        cellPostActionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        cellPostActionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.view.bringSubviewToFront(cellPostActionView)
        var originY = point.y
        if originY + cellPostActionView.actionBtnContainer.frame.height > (self.view.safeAreaLayoutGuide.layoutFrame.height) {
            originY = point.y - cellPostActionView.actionBtnContainer.frame.height - tappedViewFrame.height
        }
        cellPostActionView.actionBtnContainer.layoutIfNeeded()
        cellPostActionView.contentView.layoutIfNeeded()
        cellPostActionView.btnTopConstraint.constant = originY
        cellPostActionView.btnLeadingConstraint.constant = point.x - cellPostActionView.actionBtnContainer.frame.width
        cellPostActionView.actionBtnContainer.layoutIfNeeded()
        cellPostActionView.contentView.layoutIfNeeded()
        cellPostActionView.actionBtnContainer.isHidden = false
        self.cellActionView = cellPostActionView
        self.cellActionView?.onOutsideViewTapped = {
            [weak self] in
            self?.removeCellMoreActionView()
        }
        self.cellActionView?.onShareTapped = { [weak self] in
            if let postItem = post as? OrbisFeedPost {
                self?.performShareAction(onPost: postItem)
            }
        }
        self.cellActionView?.onReportTapped = { [weak self] in
            if let postItem = post as? OrbisFeedPost {
                self?.performReportAction(onPost: postItem)
            }
        }
        self.cellActionView?.onDeleteTapped = { [weak self] in
            if let postItem = post as? OrbisFeedPost {
                self?.performDeleteAction(onPost: postItem)
            }
        }
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.cellActionView?.actionBtnContainer.alpha = 1
        } completion: { (true) in
        }
    }
    
    func didTapMore(onCell: UITableViewCell, tappedView: UIView, post: OrbisFeedPost) {
        let location = tappedView.convert(tappedView.bounds.origin, to: self.view)
        let locationY = location.y - self.view.safeAreaInsets.top
        showPostCellActionView(inLocation: CGPoint(x: location.x + (tappedView.frame.width), y: locationY + tappedView.frame.height), item: post, tappedViewFrame: tappedView.bounds)
    }
    
    func didTapMore(onCell: UICollectionViewCell, tappedView: UIView, post: OrbisFeedPost) {
        let location = tappedView.convert(tappedView.bounds.origin, to: self.view)
        let locationY = location.y - self.view.safeAreaInsets.top
        showPostCellActionView(inLocation: CGPoint(x: location.x + (tappedView.frame.width), y: locationY + tappedView.frame.height), item: post, tappedViewFrame: tappedView.bounds)
    }
    
    private func fetchAndPerformShareLink(forPost post: OrbisFeedPost) {
        self.showOrbisLoader(disableUserInteraction: true)
        OrbisSharedPostLikeCommentManager.shared.getPostShareLink(forPost: post) { [weak self] data, err in
            if let shareLink = data as? String {
                var newPost = post
                newPost.shareLink = shareLink
                self?.postDetailViewModel.updatePost(newPost: newPost, notify: false)
                self?.performLinkShare(withLink: shareLink)
            }
            else if let error = err{
                self?.handleError(error: error)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func performLinkShare(withLink link: String) {
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [link], applicationActivities: nil)
        
        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = view
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func performDeleteAction(onPost postItem: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        showDeletePostConfirmation(post: postItem)
    }
    
    private func showDeletePostConfirmation(post: OrbisFeedPost) {
        self.showConfirmationAlert(title: AppStrings.ConfirmationPopup.confirmDelete, message: AppStrings.ConfirmationPopup.deletePostConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) {
            [weak self] (success) in
            if success {
                self?.proceedDeletePost(post: post)
            }
        }
    }
    
    private func proceedDeletePost(post: OrbisFeedPost) {
        self.showOrbisLoader(disableUserInteraction: true)
        OrbisSharedPostLikeCommentManager.shared.deletePost(post: post) { [weak self] data, err in
            if let _ = data as? String {
                self?.navigationController?.popViewController(animated: true)
            }
            else if let error = err {
                self?.handleError(error: error)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func showReportPostView(forPost post: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        let reportPopupVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "textEditPopupVC") as! TextEditPopupViewController
        reportPopupVC.modalPresentationStyle = .overFullScreen
        reportPopupVC.shouldAddFullOverlay = true
        reportPopupVC.shouldDismissViewOnTapOutside = false
        reportPopupVC.shouldProceedWithUnchanged = true
        reportPopupVC.contentTitle = AppStrings.Post.Actions.reportPost
        reportPopupVC.saveBtnTitle = AppStrings.Post.Actions.report
        reportPopupVC.textViewPlaceholder = AppStrings.Post.Actions.reportPostPlaceholder
        reportPopupVC.contentText = ""
        reportPopupVC.onSave = {
            [weak self] reportText in
            self?.proceedReportPost(forPost: post, withReportDescription: reportText)
        }
        present(reportPopupVC, animated: true, completion: nil)
    }
    
    private func proceedReportPost(forPost post: OrbisFeedPost, withReportDescription string: String) {
        self.showOrbisLoader()
        postDetailViewModel.reportPost(post: post, withText: string) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.showToastMessage(message: AppStrings.SuccessMessages.postReported)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func performShareAction(onPost postItem: OrbisFeedPost) {
        self.fetchAndPerformShareLink(forPost: postItem)
    }
    
    private func performReportAction(onPost postItem: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        self.showReportPostView(forPost: postItem)
    }
}

extension PostDetailsViewController: FeedImageFullViewDelegate {
    func didTapImage(at index: Int, inCell cell: UITableViewCell) {
        guard let imgPost = postDetailViewModel.model else { return }
        if imgPost.postType == .eventPost {
            guard let imageNames = imgPost.mediaUrls else { return }
            imageFullSizeViewer?.removeFromParent()
            imageFullSizeViewer = nil
            imageFullSizeViewer = (UIStoryboard.getViewController(inStoryboard: "Group", identifier: "orbisImageGalleryVC") as! OrbisImageGalleryViewController)
            imageFullSizeViewer?.storageDirectory = .eventImages
            imageFullSizeViewer?.imagesString = imageNames
            imageFullSizeViewer?.preselectedIndex = index
            imageFullSizeViewer?.modalPresentationStyle = .overFullScreen
            imageFullSizeViewer?.onCloseTapped = {
                [weak self] in
                self?.imageFullSizeViewer?.dismiss(animated: true) {
                    [weak self] in
                    self?.imageFullSizeViewer = nil
                }
            }
            self.present(imageFullSizeViewer!, animated: true, completion: nil)
            return
        }
        guard imgPost.postType == .imagePost else { return }
        guard let imageNames = imgPost.mediaUrls else { return }
        imageFullSizeViewer?.removeFromParent()
        imageFullSizeViewer = nil
        imageFullSizeViewer = (UIStoryboard.getViewController(inStoryboard: "Group", identifier: "orbisImageGalleryVC") as! OrbisImageGalleryViewController)
        imageFullSizeViewer?.storageDirectory = .postImages
        imageFullSizeViewer?.imagesString = imageNames
        imageFullSizeViewer?.preselectedIndex = index
        imageFullSizeViewer?.modalPresentationStyle = .overFullScreen
        imageFullSizeViewer?.onCloseTapped = {
            [weak self] in
            self?.imageFullSizeViewer?.dismiss(animated: true) {
                [weak self] in
                self?.imageFullSizeViewer = nil
            }
        }
        self.present(imageFullSizeViewer!, animated: true, completion: nil)
    }
}

extension PostDetailsViewController: UITextViewDelegate {
    private func gotoAuthView() {
        if UserSessionManager.shared.hasLoginOnboardingBeenShown {
            let authView = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authMainVC") as! AuthMainViewController
            authView.defaultSelectionIndex = 0
            self.navigationController?.pushViewController(authView, animated: true)
        }
        else {
            UserSessionManager.shared.setLoginOnboardingShown()
            let authOptionPickerVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authOptionPickerVC") as! AuthOptionPickerViewController
            self.navigationController?.pushViewController(authOptionPickerVC, animated: true)
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return false
        }
        return true
    }
}

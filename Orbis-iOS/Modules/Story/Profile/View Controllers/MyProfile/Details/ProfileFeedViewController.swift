//
//  ProfileFeedViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/04/2021.
//

import UIKit

class ProfileFeedViewController: OrbisLocalizableViewController {

    @IBOutlet weak var feedTableView: UITableView!
    
    struct UserFeedCellIdentifier {
        static let textPostCell = "textPostCell"
        static let imagePostCell = "imagePostCell"
        static let checkinPostCell = "checkinPostCell"
        static let audioPostCell = "audioPostCell"
        static let videoPostCell = "videoPostCell"
        static let eventPostCell = "eventPostCell"
    }
    
    weak var parallexScrollDelegate: OrbisParallexScrollDelegate?
    
    var viewModel: ProfileFeedViewModel!
    var scrollViewCurrentOffset: CGFloat = 0
    var isFeedLoading = false
    var refreshControl = UIRefreshControl()
    
    weak var cellActionView: PostCellActionView?
    var currentPlayigAudio: AudioPostTableViewCell?
    var currentPlayingVideo: VideoPostTableViewCell?
    
    var imageFullSizeViewer: OrbisImageGalleryViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewSetup()
        handleViewModelActions()
        addObservers()
        resetData()
        loadFeedData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didCompletePendingPost(_:)), name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didErrorOccuredInPendingPostCreation(_:)), name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didCompletePostCreation(_:)), name: NSNotification.Name(AppNotificationKeys.PostCreate.postCreateCompleted), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(commentCountUpdated(_:)), name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postUpdated(_:)), name: NSNotification.Name(AppNotificationKeys.Post.postUpdated), object: nil)
    }
    
    @objc private func postUpdated(_ notification: NSNotification) {
        guard let post = notification.object as? OrbisFeedPost else { return }
        viewModel.updatePost(newPost: post)
    }
    
    @objc private func commentCountUpdated(_ notification: NSNotification) {
        guard let countTuple = notification.object as? (String, Int) else { return }
        viewModel.updateCommentCount(key: countTuple.0, count: countTuple.1)
        feedTableView.reloadData()
    }
    
    @objc private func didCompletePostCreation(_ notification: NSNotification) {
        refreshFeed()
    }
    
    @objc private func didCompletePendingPost(_ notification: NSNotification) {
        guard let object = notification.object as? OrbisFeedPost, object.user?.userKey == self.viewModel.user.userKey else { return }
        resetData()
        loadFeedData()
    }
    
    @objc private func didErrorOccuredInPendingPostCreation(_ notification: NSNotification) {
        guard let object = notification.object as? (Error, OrbisFeedPost), object.1.user?.userKey == self.viewModel.user.userKey else { return }
        self.handleError(error: object.0)
        resetData()
        loadFeedData()
    }
    
    
    func tableViewSetup() {
        feedTableView.register(UINib(nibName: "ImagePostTableViewCell", bundle: nil), forCellReuseIdentifier: UserFeedCellIdentifier.imagePostCell)
        feedTableView.register(UINib(nibName: "TextPostTableViewCell", bundle: nil), forCellReuseIdentifier: UserFeedCellIdentifier.textPostCell)
        feedTableView.register(UINib(nibName: "AudioPostTableViewCell", bundle: nil), forCellReuseIdentifier: UserFeedCellIdentifier.audioPostCell)
        feedTableView.register(UINib(nibName: "VideoPostTableViewCell", bundle: nil), forCellReuseIdentifier: UserFeedCellIdentifier.videoPostCell)
        feedTableView.register(UINib(nibName: "CheckinPostTableViewCell", bundle: nil), forCellReuseIdentifier: UserFeedCellIdentifier.checkinPostCell)
        feedTableView.register(UINib(nibName: "EventPostTableViewCell", bundle: nil), forCellReuseIdentifier: UserFeedCellIdentifier.eventPostCell)
        feedTableView.register(OrbisViewAttachedTableViewCell.self, forCellReuseIdentifier: "emptyFeedDataCell")
        
        feedTableView.dataSource = self
        feedTableView.delegate = self
        
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        feedTableView.addSubview(refreshControl)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshFeed()
    }
    
    private func refreshFeed() {
        refreshControl.endRefreshing()
        resetData()
        loadFeedData()
    }
    
    func resetData() {
        viewModel.initializePagination()
        isFeedLoading = false
        feedTableView.reloadData()
    }
    
    func loadFeedData() {
        isFeedLoading = true
        self.parallexScrollDelegate?.showCommonLoader()
        viewModel.loadUserFeed()
    }
    
    func loadMoreFeed() {
        isFeedLoading = true
        self.parallexScrollDelegate?.showCommonLoader()
        viewModel.loadMoreUserFeed()
    }
    
    private func handleViewModelActions() {
        viewModel.onUserFeedFetched = { [weak self] in
            self?.parallexScrollDelegate?.hideCommonLoader()
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onUserFeedFetchedCompletePagination = { [weak self] in
            self?.parallexScrollDelegate?.hideCommonLoader()
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onUserFeedFetchError = { [weak self] (error) in
            self?.parallexScrollDelegate?.hideCommonLoader()
            self?.handleError(error: error)
            self?.isFeedLoading = false
        }
        viewModel.onPostUpdated = {
            [weak self] in
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
    }

}

extension ProfileFeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func getCheckinTableViewCell(at index: Int, tableView: UITableView) -> UITableViewCell {
        let model = viewModel.getFeedPostModel(at: index)
        guard model.feedPostType == .slider else { return UITableViewCell(frame: .zero) }
        let cell = tableView.dequeueReusableCell(withIdentifier: UserFeedCellIdentifier.checkinPostCell) as! CheckinPostTableViewCell
        let cellViewModel = CheckingPostViewModel(checkinPosts: model.slider!, pageIndex: model.currentSliderPageIndex)
        cell.viewModel = cellViewModel
        cell.actionDelegate = self
        cell.viewModel.onPageIndexChanged = {
            [weak self] page in
            self?.viewModel.updateSliderPageIndex(at: index, value: page)
        }
        if cellViewModel.isPendingPost {
            cell.addLoadingOverlay()
        }
        else {
            cell.removeExistingLoadingOverlay()
        }
        cell.layoutIfNeeded()
        return cell
    }
    
    private func getPostTableViewCell(ofType type: OrbisPostType, tableView: UITableView, atIndex index: Int) -> UITableViewCell {
        let model = viewModel.getFeedPostModel(at: index)
        guard model.feedPostType == .post else { return UITableViewCell(frame: .zero) }
        switch type {
        case .textPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: UserFeedCellIdentifier.textPostCell) as! TextPostTableViewCell
            let cellViewModel = TextPostCellViewModel(data: model.post!)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: UserFeedCellIdentifier.imagePostCell) as! ImagePostTableViewCell
            let cellViewModel = ImagePostCellViewModel(data: model.post!, pageIndex: model.currentSliderPageIndex)
            cell.viewModel = cellViewModel
            cell.actionDelegate = self
            cell.imageFullSizeDeleage = self
            cell.viewModel.onPageIndexChanged = {
                [weak self] page in
                self?.viewModel.updateSliderPageIndex(at: index, value: page)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: UserFeedCellIdentifier.audioPostCell) as! AudioPostTableViewCell
            let cellViewModel = AudioPostCellViewModel(data: model.post!)
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
            return UITableViewCell(frame: .zero)
        case .eventPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: UserFeedCellIdentifier.eventPostCell) as! EventPostTableViewCell
            let cellViewModel = EventPostCellViewModel(data: model.post!)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: UserFeedCellIdentifier.videoPostCell) as! VideoPostTableViewCell
            let cellViewModel = VideoPostCellViewModel(data: model.post!)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        if viewModel.hasFeedPosts {
            return viewModel.feedCount
        }
        else {
            if isFeedLoading {
                return viewModel.feedCount
            }
            return viewModel.feedCount + 1 // for empty cell
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard viewModel.hasFeedPosts else {
            if isFeedLoading {
                return UITableViewCell(frame: .zero)
            }
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "emptyFeedDataCell") as! OrbisViewAttachedTableViewCell
            let emptyContentView = EmptyDataContentView(description: AppErrorStrings.userFeedEmpty, image: #imageLiteral(resourceName: "profile-no-photos-ic"), imageSize: CGSize(width: 207, height: 168), contentPadding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), backgroundColor: .clear)
            emptyContentView.layoutIfNeeded()
            emptyCell.addContent(view: emptyContentView)
            emptyCell.attachedView.layoutIfNeeded()
            emptyCell.layoutIfNeeded()
            return emptyCell
        }
        let model = viewModel.getFeedPostModel(at: indexPath.row)
        switch model.feedPostType {
        case .slider:
            return getCheckinTableViewCell(at: indexPath.row, tableView: tableView)
        case .post:
            let type = model.post?.postType ?? .checkinPost
            return getPostTableViewCell(ofType: type, tableView: tableView, atIndex: indexPath.row)
        case .nativeAd:
            return UITableViewCell(frame: .zero)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 115.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.feedCount - 1
        if indexPath.row == loadMoreIndex && !isFeedLoading && !viewModel.hasItemsLastPageReached {
            self.loadMoreFeed()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let audioCell = cell as? AudioPostTableViewCell {
            audioCell.pausePlayer()
            if self.currentPlayigAudio?.viewModel.model.postKey == audioCell.viewModel.model.postKey {
                self.currentPlayigAudio = nil
            }
        }
        if let videoCell = cell as? VideoPostTableViewCell {
            if let player = videoCell.player {
                player.pause()
            }
            if self.currentPlayigAudio?.viewModel.model.postKey == videoCell.viewModel.model.postKey {
                self.currentPlayingVideo = nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getFeedPostModel(at: indexPath.row)
        guard model.post?.postType == .eventPost, let event = model.post else { return }
        showEventDetailsView(event: event)
    }
    
    private func showEventDetailsView(event: OrbisFeedPost) {
        let eventsDetailVC = UIStoryboard.getViewController(inStoryboard: "Events", identifier: "eventsDetailVC") as! EventDetailsViewController
        eventsDetailVC.viewModel = EventDetailsViewModel(event: event)
        let navVC = OrbisNavigationController(rootViewController: eventsDetailVC)
        navVC.modalPresentationStyle = .overFullScreen
        eventsDetailVC.onPostUpdated = {
            [weak self] post in
            self?.viewModel.updatePost(newPost: post)
        }
        self.presentPanModal(navVC)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        parallexScrollDelegate?.childScrollViewDidScroll(scrollView)
    }
}

extension ProfileFeedViewController: PostCellActionDelegate {
    
    func didTapEvenAttend(onCell: UITableViewCell, post: OrbisFeedPost) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.attendCancelAttendEvent(event: post) { data, err in
            if let error = err {
                self.handleError(error: error)
            }
            self.hideOrbisLoader()
        }
    }
    
    func didTapViewMore(onCell: UITableViewCell, post: OrbisFeedPost, maxLines: Int) {
        guard let index = self.feedTableView.indexPath(for: onCell) else { return }
        guard let postIndex = self.viewModel.getIndex(for: post), postIndex == index.row else { return }
        viewModel.replaceExpandedPost(expandedPost: post)
        feedTableView.beginUpdates()
        let point = onCell.convert(CGPoint.zero, to: feedTableView)
        if let indexPath = feedTableView.indexPathForRow(at: point) as IndexPath? {
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
                    self?.feedTableView.scrollToRow(at: indexPath, at: .top, animated: false)
                }
            }
        }
        feedTableView.reloadRows(at: [index], with: .none)
        feedTableView.endUpdates()
    }
    
    func didTapViewMore(onCell: UICollectionViewCell, post: OrbisFeedPost, maxLines: Int) {
    }
    
    private func performLikeUnlike(onPost post: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        viewModel.likeUnlikePost(post: post)
    }
    
    func didTapLikeStack(onCell cell: UITableViewCell, post: OrbisFeedPost) {
        performLikeUnlike(onPost: post)
    }
    
    func didTapLikeStack(onCell cell: UICollectionViewCell, post: OrbisFeedPost) {
        performLikeUnlike(onPost: post)
    }
    
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
    
    private func gotoUserProfileView(withUser user: OrbisUser) {
        let isViewingSelf = (user.userKey == UserSessionManager.shared.currentUser?.userKey)
        guard !isViewingSelf else { return }
        if user.deleted == true  {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        let profileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        profileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: isViewingSelf)
        self.parallexScrollDelegate?.getParentViewController().navigationController?.pushViewController(profileVC, animated: true)
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
        self.parallexScrollDelegate?.getParentViewController().navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.parallexScrollDelegate?.getParentViewController().navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    func didTapLocationStack(onCell cell: UITableViewCell, place: OrbisPlace) {
        gotoPlaceDetailView(place: place)
    }
    
    func didTapLocationStack(onCell cell: UICollectionViewCell, place: OrbisPlace) {
        gotoPlaceDetailView(place: place)
    }
    
    private func openCommentView(forPost post: OrbisFeedPost) {
        let postCommentsVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "postCommentsVC") as! CommentsViewController
        let navVC = OrbisNavigationController(rootViewController: postCommentsVC)
        navVC.modalPresentationStyle = .overFullScreen
        postCommentsVC.viewModel = PostCommentsViewModel(post: post)
        presentPanModal(navVC)
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

    private func fetchAndPerformShareLink(forPost post: OrbisFeedPost) {
        self.showOrbisLoader(disableUserInteraction: true)
        OrbisSharedPostLikeCommentManager.shared.getPostShareLink(forPost: post) { [weak self] data, err in
            if let shareLink = data as? String {
                var newPost = post
                newPost.shareLink = shareLink
                self?.viewModel.updatePost(newPost: newPost, notify: false)
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
            if let key = data as? String {
                self?.viewModel.removePost(postKey: key)
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
        viewModel.reportPost(post: post, withText: string) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.showToastMessage(message: AppStrings.SuccessMessages.postReported)
            }
            self?.hideOrbisLoader()
        }
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
                self?.fetchAndPerformShareLink(forPost: postItem)
            }
        }
        self.cellActionView?.onReportTapped = {
            [weak self] in
            if let postItem = post as? OrbisFeedPost {
                self?.showReportPostView(forPost: postItem)
            }
        }
        self.cellActionView?.onDeleteTapped = {
            [weak self] in
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
}

extension ProfileFeedViewController: FeedImageFullViewDelegate {
    func didTapImage(at index: Int, inCell cell: UITableViewCell) {
        guard let cellIndex = self.feedTableView.indexPath(for: cell)?.row else { return }
        guard let imgPost = viewModel.getFeedPostModel(at: cellIndex).post else { return }
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

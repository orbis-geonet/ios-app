//
//  GroupDetailsViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import UIKit
import ExpandableLabel

class GroupDetailsViewController: OrbisLocalizableViewController {
    @IBOutlet weak var feedTableView: UITableView!
    @IBOutlet weak var addBtnIconView: UIImageView!
    @IBOutlet weak var addBtn: UIButton!
    
    @IBOutlet weak var groupGotoEventBtnView: RoundedView!
    @IBOutlet weak var eventGotoFeedBtnView: RoundedView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addTapped(_ sender: Any) {
        handleAddBtnTap()
    }
    @IBAction func eventBtnTapped(_ sender: Any) {
        showEventListView()
    }
    @IBAction func groupFeedBtnTapped(_ sender: Any) {
        showGroupFeedListView()
    }
    
    struct GroupDetailFeedCellIdentifier {
        static let groupHeaderCell = "groupHeaderCell"
        static let textPostCell = "textPostCell"
        static let imagePostCell = "imagePostCell"
        static let checkinPostCell = "checkinPostCell"
        static let audioPostCell = "audioPostCell"
        static let videoPostCell = "videoPostCell"
        static let eventPostCell = "eventPostCell"
        static let eventCellTitleCell = "eventTitleCell"
    }
    
    var refreshControl = UIRefreshControl()
    var viewModel: GroupDetailViewModel!
    var headerCollapseState: Bool = true
    var hasDataLoaded: Bool = false
    weak var groupCellActionView: GroupUserActionPopupView?
    weak var cellActionView: PostCellActionView?
    var currentPlayigAudio: AudioPostTableViewCell?
    var currentPlayingVideo: VideoPostTableViewCell?
    
    var loaderCount = 0
    var isFeedLoading: Bool = false
    var isEventLoading = false
    
    var imageFullSizeViewer: OrbisImageGalleryViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewSetup()
        updateViewScene()
        syncData()
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
    
    @objc private func didCompletePendingPost(_ notification: NSNotification) {
        guard let object = notification.object as? OrbisFeedPost, object.group?.groupKey == self.viewModel.model.groupKey else { return }
        resetData()
        loadFeedData()
    }
    
    @objc private func didErrorOccuredInPendingPostCreation(_ notification: NSNotification) {
        guard let object = notification.object as? (Error, OrbisFeedPost), object.1.group?.groupKey == self.viewModel.model.groupKey else { return }
        self.handleError(error: object.0)
        resetData()
        loadFeedData()
    }
    
    private func showEventListView() {
        viewModel.isEventsView = true
        updateViewScene()
        if !viewModel.hasFeedPosts {
            resetEventData()
            loadEventData()
        }
    }
    
    private func showGroupFeedListView() {
        viewModel.isEventsView = false
        updateViewScene()
        if !viewModel.hasFeedPosts {
            resetData()
            loadFeedData()
        }
    }
    
    private func showCreateEventPage() {
        guard viewModel.isLoggedIn else {
            gotoAuthView()
            return
        }
        let createEventVC = UIStoryboard.getViewController(inStoryboard: "Events", identifier: "createEventVC") as! CreateEventViewController
        createEventVC.viewModel = CreatePostViewModel(defaultPublisherGroup: viewModel.model, isSelfPublisher: false, selectedPlace: nil)
        createEventVC.shouldDisableDropDownAction = true
        createEventVC.onCreatePostSuccess = {
            [weak self] data in
            self?.refreshFeed()
        }
        createEventVC.modalPresentationStyle = .overFullScreen
        presentPanModal(createEventVC)
    }
    
    private func handleViewModelActions() {
        viewModel.onGroupDetailSyncError = {
            [weak self] error in
            self?.refreshControl.endRefreshing()
            self?.handleError(error: error)
            self?.tryHideLoader()
        }
        viewModel.onGroupDetailSyncSuccess = {
            [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.updateViewScene(changeEventSelection: false)
            self?.hasDataLoaded = true
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
                self?.displaySubscriptionAlertIfNecessary()
            }
        }
        viewModel.onGroupJoinError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.tryHideLoader()
        }
        viewModel.onGroupLeaveError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.tryHideLoader()
        }
        viewModel.onGroupLeaveSuccess = {
            [weak self] in
            self?.tryHideLoader()
            self?.navigationController?.popViewController(animated: true)
        }
        viewModel.onGroupFeedFetched = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onGroupFeedFetchedCompletePagination = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onGroupFeedFetchError = { [weak self] (error) in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
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
        viewModel.onGroupDeleteError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.tryHideLoader()
        }
        viewModel.onGroupDeleteSuccess = {
            [weak self] in
            self?.showToastMessage(message: "\(AppStrings.Group.group) \(self?.viewModel.model.name ?? "") \(AppStrings.SuccessMessages.hasBeenDeleted)")
            self?.tryHideLoader()
            self?.navigationController?.popViewController(animated: true)
        }
        viewModel.onGroupStoriesUnhideError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.tryHideLoader()
        }
        
        viewModel.onEventFeedFetched = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isEventLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onEventFeedFetchedCompletePagination = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isEventLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onEventFeedFetchError = { [weak self] (error) in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.handleError(error: error)
            self?.isFeedLoading = false
        }
        viewModel.onEventPostUpdated = {
            [weak self] in
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
    }
    
    private func tryHideLoader() {
        loaderCount -= 1
        if loaderCount < 0 {
            loaderCount = 0
        }
        guard loaderCount == 0 else { return }
        self.hideOrbisLoader()
    }
    
    private func syncData() {
        self.loaderCount += 1
        self.view.showOrbisLoader()
        viewModel.syncGroupDataWithServer()
    }
    
    func resetData() {
        viewModel.initializePagination()
        isFeedLoading = false
        feedTableView.reloadData()
    }
    
    func loadFeedData() {
        isFeedLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadGroupFeed()
    }
    
    func loadMoreFeed() {
        isFeedLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadMoreGroupFeed()
    }
    
    func resetEventData() {
        viewModel.initializeEventsPagination()
        isEventLoading = false
        feedTableView.reloadData()
    }
    
    func loadEventData() {
        isEventLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadGroupEvents()
    }
    
    func loadMoreEvent() {
        isEventLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadMoreGroupEvents()
    }
    
    private func updateViewScene(changeEventSelection: Bool = true) {
        let isEventsView = viewModel.isEventsView
        eventGotoFeedBtnView.isHidden = !isEventsView
        groupGotoEventBtnView.isHidden = isEventsView
        if changeEventSelection {
            UIView.transition(with: feedTableView, duration: 0.5, options: [.curveEaseInOut, .transitionCrossDissolve], animations: {
                                self.feedTableView.reloadData()},
                              completion: nil)
        }
        let addIcon = UIImage(named: "plus-ic")
        let joinGroupIcon = UIImage(named: "add-member-ic")
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.addBtnIconView.image = self.viewModel.isMember ? addIcon : joinGroupIcon
        }
    }
    
    private func handleAddBtnTap() {
        guard hasDataLoaded else { return }
        guard viewModel.isLoggedIn else {
            self.gotoAuthView()
            return
        }
        if viewModel.isMember {
            guard !viewModel.isBanned else {
                self.showToastMessage(message: AppErrorStrings.userBannedFromPosting)
                return
            }
            // handle add post
            if viewModel.isEventsView {
                showCreateEventPage()
            }
            else {
                openCreateGroupPostPage()
            }
        }
        else {
            // handle request join group
            tryJoinGroup()
        }
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
    
    private func tryJoinGroup() {
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.tryJoinGroup()
    }
    
    private func openCreateGroupPostPage() {
        let createPostVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "createPostVC") as! CreatePostViewController
        createPostVC.viewModel = CreatePostViewModel(defaultPublisherGroup: viewModel.model)
        createPostVC.createPostInvoker = CreatePostInvoker.group
        createPostVC.shouldDisableDropDownAction = true
        createPostVC.onCreatePostSuccess = {
            [weak self] data in
            self?.refreshFeed()
            if let feedPost = data as? OrbisFeedPost, let placeKey = feedPost.place?.placeKey, CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey){
                self?.goToMapView(withPost: feedPost)
            }
            else if let placeData = data as? OrbisPlace {
                self?.gotoPlaceDetailView(place: placeData)
            }
        }
        createPostVC.modalPresentationStyle = .overFullScreen
        presentPanModal(createPostVC)
    }
    
    func tableViewSetup() {
        feedTableView.register(UINib(nibName: "GroupDetailHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.groupHeaderCell)
        feedTableView.register(UINib(nibName: "ImagePostTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.imagePostCell)
        feedTableView.register(UINib(nibName: "TextPostTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.textPostCell)
        feedTableView.register(UINib(nibName: "AudioPostTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.audioPostCell)
        feedTableView.register(UINib(nibName: "VideoPostTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.videoPostCell)
        feedTableView.register(UINib(nibName: "CheckinPostTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.checkinPostCell)
        feedTableView.register(UINib(nibName: "EventPostTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.eventPostCell)
        feedTableView.register(UINib(nibName: "FeedTitleTableViewCell", bundle: nil), forCellReuseIdentifier: GroupDetailFeedCellIdentifier.eventCellTitleCell)
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
        syncData()
        updateViewScene(changeEventSelection: false)
        if viewModel.isEventsView {
            resetEventData()
            loadEventData()
        }
        else {
            resetData()
            loadFeedData()
        }
    }

    private func goToMapView(withPost post: OrbisFeedPost) {
        guard var place = post.place else { return }
        guard let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first else { return }
        guard let rootNavVC = keyWindow.rootViewController as? UINavigationController else { return }
        place.lastSize = 500
        place.lastCheckInTimestamp = Date().iso8601withFractionalSeconds
        if place.lastSizeChangeTimestamp == nil {
            place.lastSizeChangeTimestamp = place.lastCheckInTimestamp
        }
        if place.dominantGroup == nil {
            place.dominantGroup = post.group
            place.dominantGroupKey = post.group?.groupKey
        }
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            self.navigationController?.popToRootViewController(animated: true)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                homeVC.handlePlaceCheckinSuccess(place: place)
            }
        }
    }
}

extension GroupDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func getCheckinTableViewCell(at index: Int, tableView: UITableView) -> UITableViewCell {
        let model = viewModel.getFeedPostModel(at: index)
        guard model.feedPostType == .slider else { return UITableViewCell(frame: .zero) }
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.checkinPostCell) as! CheckinPostTableViewCell
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
    
    private func getEventPostTableViewCell(tableView: UITableView, atIndex index: Int) -> UITableViewCell {
        let model = viewModel.getEventPostModel(at: index)
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.eventPostCell) as! EventPostTableViewCell
        let cellViewModel = EventPostCellViewModel(data: model)
        cell.actionDelegate = self
        cell.viewModel = cellViewModel
        cell.imageFullSizeDeleage = self
        if cellViewModel.isPendingPost {
            cell.addLoadingOverlay()
        }
        else {
            cell.removeExistingLoadingOverlay()
        }
        return cell
    }
    
    private func getPostTableViewCell(ofType type: OrbisPostType, tableView: UITableView, atIndex index: Int) -> UITableViewCell {
        let model = viewModel.getFeedPostModel(at: index)
        guard model.feedPostType == .post else { return UITableViewCell(frame: .zero) }
        switch type {
        case .textPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.textPostCell) as! TextPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.imagePostCell) as! ImagePostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.audioPostCell) as! AudioPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.eventPostCell) as! EventPostTableViewCell
            let cellViewModel = EventPostCellViewModel(data: model.post!)
            cell.actionDelegate = self
            cell.viewModel = cellViewModel
            cell.imageFullSizeDeleage = self
            if cellViewModel.isPendingPost {
                cell.addLoadingOverlay()
            }
            else {
                cell.removeExistingLoadingOverlay()
            }
            return cell
        case .videoPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.videoPostCell) as! VideoPostTableViewCell
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
        guard viewModel != nil else { return 0 }
        if viewModel.isEventsView {
            if viewModel.hasFeedPosts {
                return viewModel.eventPostsCount
            }
            else {
                if isEventLoading {
                    return viewModel.eventPostsCount
                }
                return viewModel.eventPostsCount + 1 // for empty cell
            }
        }
        else {
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
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            // load header
            let headerCell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.groupHeaderCell) as! GroupDetailHeaderTableViewCell
            headerCell.groupDescriptionLabel.delegate = self
            let linkFont = UIFont(name: "Roboto-Black", size: CGFloat(16).relativeToIphone8Width())!
            headerCell.groupDescriptionLabel.setLessLinkWith(lessLink: AppStrings.viewLess, attributes: [
                .foregroundColor:UIColor(named: AppColors.appBlue.rawValue)!,
                .font: linkFont
            ], position: .left)
            headerCell.groupDescriptionLabel.collapsedAttributedLink = NSAttributedString(string: AppStrings.viewMore, attributes: [
                .foregroundColor:UIColor(named: AppColors.appBlue.rawValue)!,
                .font: linkFont
            ])
            headerCell.viewModel = GroupDetailHeaderViewModel(group: viewModel.model)
            headerCell.layoutIfNeeded()
            headerCell.groupDescriptionLabel.shouldCollapse = true
            headerCell.groupDescriptionLabel.numberOfLines = 3
            headerCell.groupDescriptionLabel.collapsed = headerCollapseState
            headerCell.onMembersCountTapped = {
                [weak self] in
                self?.showMembersList()
            }
            headerCell.onPlacesCountTapped = {
                [weak self] in
                self?.showGroupPlaces()
            }
            headerCell.onGroupMoreBtnTapped = {
                [weak self] (cell, view) in
                self?.didTapMore(onCell: cell, tappedView: view)
            }
            headerCell.onEditSubscriptionTapped = {
                [weak self] in
                self?.showSubscription()
            }
            headerCell.onActivityTapped = {
                [weak self] in
                self?.showSubscriptionActivity()
            }
            headerCell.onCreateSubscriptionTapped = {
                [weak self] in
                self?.showCreateSubscription()
            }
            headerCell.onSubscriptionTapped = {
                [weak self] in
                self?.showSubscription()
            }
            headerCell.onUpdateSubscriptionTapped = {
                [weak self] in
                self?.showSubscription()
            }
            return headerCell
        }
        if indexPath.row == 1 {
            if viewModel.isEventsView {
                // load event title cell
                let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.eventCellTitleCell) as! FeedTitleTableViewCell
                cell.titleLabel.text = AppStrings.Events.events
                return cell
            }
            else {
                // load feed title cell
                let cell = tableView.dequeueReusableCell(withIdentifier: GroupDetailFeedCellIdentifier.eventCellTitleCell) as! FeedTitleTableViewCell
                cell.titleLabel.text = AppStrings.feed
                return cell
            }
        }
        guard viewModel.hasFeedPosts else {
            if viewModel.isEventsView && isEventLoading {
                return UITableViewCell(frame: .zero)
            }
            else if !viewModel.isEventsView && isFeedLoading {
                return UITableViewCell(frame: .zero)
            }
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "emptyFeedDataCell") as! OrbisViewAttachedTableViewCell
            let emptyContentView = EmptyDataContentView(description: AppErrorStrings.groupFeedEmpty, image: #imageLiteral(resourceName: "profile-no-photos-ic"), imageSize: CGSize(width: 207, height: 168), contentPadding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), backgroundColor: .clear)
            emptyContentView.layoutIfNeeded()
            emptyCell.addContent(view: emptyContentView)
            emptyCell.attachedView.layoutIfNeeded()
            emptyCell.layoutIfNeeded()
            return emptyCell
        }
        if viewModel.isEventsView {
            return getEventPostTableViewCell(tableView: tableView, atIndex: indexPath.row - 2)
        }
        let model = viewModel.getFeedPostModel(at: indexPath.row - 2)
        switch model.feedPostType {
        case .slider:
            return getCheckinTableViewCell(at: indexPath.row - 2, tableView: tableView)
        case .post:
            let type = model.post?.postType ?? .checkinPost
            return getPostTableViewCell(ofType: type, tableView: tableView, atIndex: indexPath.row -  2)
        case .nativeAd:
            return UITableViewCell(frame: .zero)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if viewModel.hasFeedPosts {
            return 115.toCGFloat.relativeToIphone8Width()
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !viewModel.isEventsView else {
            let loadMoreIndex = viewModel.eventPostsCount - 1
            if indexPath.row == loadMoreIndex && !isEventLoading && !viewModel.hasEventsItemLastPageReached {
                self.loadMoreEvent()
            }
            return
        }
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
        guard indexPath.row > 1 else { return }
        if viewModel.isEventsView {
            let model = viewModel.getEventPostModel(at: indexPath.row - 2)
            showEventDetailsView(event: model)
        }
        else {
            let model = viewModel.getFeedPostModel(at: indexPath.row - 2)
            guard let post = model.post, post.postType == .eventPost else {
                return
            }
            showEventDetailsView(event: post)
        }
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
    
    private func showMembersList() {
        let membersListVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupMembersListVC") as! GroupMembersListViewController
        membersListVC.viewModel = GroupMembersListViewModel(group: self.viewModel.model)
        membersListVC.groupAdminListDataSource = self
        self.navigationController?.pushViewController(membersListVC, animated: true)
    }
    
    private func showGroupPlaces() {
        let membersListVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupPlacesListVC") as! GroupOwnedPlacesViewController
        membersListVC.viewModel = GroupOwnedPlacesViewModel(group: self.viewModel.model)
        self.navigationController?.pushViewController(membersListVC, animated: true)
    }

    private func showSubscription() {
        guard UserSessionManager.shared.isUserInBrazil else { return } // Remove this once subscription is set to available everywhere
        let listVC = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "subscriptionVC") as! SubscriptionListViewController
        listVC.viewModel = SubscriptionListViewModel(group: self.viewModel.model)
        self.navigationController?.pushViewController(listVC, animated: true)
        
    }

    private func showCreateSubscription() {
        guard UserSessionManager.shared.isUserInBrazil else { return } // Remove this once subscription is set to available everywhere
        let createSubscriptionVC = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "createSubscriptionVC") as! CreateSubscriptionViewController
        createSubscriptionVC.subscriptionCreated = { [weak self] status in
            self?.syncData()
        }
        createSubscriptionVC.viewModel = SubscriptionCreateEditViewModel(groupKey: self.viewModel.model.groupKey ?? "")
        self.navigationController?.pushViewController(createSubscriptionVC, animated: true)
    }

    private func showSubscriptionActivity() {
        guard UserSessionManager.shared.isUserInBrazil else { return } // Remove this once subscription is set to available everywhere
        let subscriptionActivityVC = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "subscriptionActivityVC") as! SubscriptionActivityViewController
        subscriptionActivityVC.group = viewModel.model
        self.navigationController?.pushViewController(subscriptionActivityVC, animated: true)
    }
    
    private func displaySubscriptionAlertIfNecessary() {
        guard UserSessionManager.shared.isUserInBrazil else { return } // Remove this once subscription is set to available everywhere
        if viewModel.isMainAdmin && UserSessionManager.shared.hasGroupMainAdminSubscriptionPopupShown {
            return
        }
        guard !(viewModel.isSubscriptionActive && viewModel.hasSubscription) else { return }
        if viewModel.isMember && UserSessionManager.shared.hasNormalUserSubscriptionPopupShown {
            return
        }
        guard viewModel.isMember else { return }
        let alertVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "illustrativePopupAlertVC") as! IllustrativePopupViewController
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.shouldDismissViewOnTapOutside = false
        alertVC.shouldAddFullOverlay = true
        alertVC.type = viewModel.isMainAdmin ? .adminSubscriptionCreation : .userSubscriptionFeature
        if(viewModel.isMainAdmin) {
            UserSessionManager.shared.setGroupMainAdminSubscriptionPopupShown()
        } else {
            UserSessionManager.shared.setNormalUserSubscriptionPopupShown()
        }
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension GroupDetailsViewController: GroupAdminsListFetchDataSource {
    func getBannedUsersList() -> [String] {
        return self.viewModel.getBannedUsers()
    }
    
    func banUnbanUserFromGroup(user: OrbisUser, completion: @escaping responseBlock) {
        self.viewModel.tryBanUnbanUserFromGroup(forUser: user, completion: completion)
    }
    
    func getAdminsList() -> [String] {
        return self.viewModel.getGroupAdmins()
    }
    
    func makeRemoveAdminRequest(forUser user: OrbisUser, completion: @escaping responseBlock) {
        self.viewModel.tryMakeRemoveAdmin(forUser: user, completion: completion)
    }
}

extension GroupDetailsViewController: ExpandableLabelDelegate {
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        feedTableView.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: feedTableView)
        if let indexPath = feedTableView.indexPathForRow(at: point) as IndexPath? {
            headerCollapseState = false
            DispatchQueue.main.async { [weak self] in
                self?.feedTableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        feedTableView.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        feedTableView.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: feedTableView)
        if let indexPath = feedTableView.indexPathForRow(at: point) as IndexPath? {
            headerCollapseState = true
            DispatchQueue.main.async { [weak self] in
                self?.feedTableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        feedTableView.endUpdates()
    }
}

extension GroupDetailsViewController {
    private func removeGroupMoreActionView() {
        groupCellActionView?.removeFromSuperview()
        groupCellActionView = nil
    }
    
    private func showGroupMoreActionView(inLocation point: CGPoint, tappedViewFrame: CGRect) {
        removeGroupMoreActionView()
        let groupUserActionView = GroupUserActionPopupView(frame: self.view.bounds)
        groupUserActionView.actionBtnContainer.alpha = 0
        self.view.addSubview(groupUserActionView)
        groupUserActionView.translatesAutoresizingMaskIntoConstraints = false
        groupUserActionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        groupUserActionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        groupUserActionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        groupUserActionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.view.bringSubviewToFront(groupUserActionView)
        var originY = point.y
        if originY + groupUserActionView.actionBtnContainer.frame.height > (self.view.safeAreaLayoutGuide.layoutFrame.height) {
            originY = point.y - groupUserActionView.actionBtnContainer.frame.height - tappedViewFrame.height
        }
        groupUserActionView.btnTopConstraint.constant = originY
        groupUserActionView.btnTrailingConstraint.constant = self.view.frame.width - point.x
        let deleteBtnHidden = !(viewModel.isAdmin || viewModel.isSuperAdmin)
        let leaveBtnHidden = !viewModel.isLeaveBtnVisible
        let unhideStoriesBtnHidden = !viewModel.isStoriesHidden
        let unfollowBtnHidden = !viewModel.isMember
        let isMainAdminWithSubscription = viewModel.isMainAdmin && viewModel.hasSubscription
        
        var activateSubscriptionBtnHidden = !(isMainAdminWithSubscription && !viewModel.isSubscriptionActive)
        var deactivateSubscriptionBtnHidden = !(isMainAdminWithSubscription && viewModel.isSubscriptionActive)
        
        if !UserSessionManager.shared.isUserInBrazil {
            activateSubscriptionBtnHidden = true
            deactivateSubscriptionBtnHidden = true
        } // Remove this once subscription is set to available everywhere

        groupUserActionView.unhideStoriesLabel.text = viewModel.unhideStoriesBtnText
        groupUserActionView.deleteLabel.text = viewModel.deleteBtnText
        groupUserActionView.followUnfollowLabel.text = viewModel.followUnfollowText
        groupUserActionView.flagLabel.text = viewModel.reportBtnText
        groupUserActionView.leaveLabel.text = viewModel.leaveBtnText
        groupUserActionView.unhideStoriesView.isHidden = unhideStoriesBtnHidden
        groupUserActionView.deleteView.isHidden = deleteBtnHidden
        groupUserActionView.leaveView.isHidden = leaveBtnHidden
        groupUserActionView.followUnfollowView.isHidden = unfollowBtnHidden
        groupUserActionView.flagView.isHidden = false
        groupUserActionView.activateSubscriptionLabel.text = viewModel.activateSubscriptionBtnText
        groupUserActionView.activateSubscriptionView.isHidden = activateSubscriptionBtnHidden
        groupUserActionView.deactivateSubscriptionLabel.text = viewModel.deactivateSubscriptionBtnText
        groupUserActionView.deactivateSubscriptionView.isHidden = deactivateSubscriptionBtnHidden
        
        groupUserActionView.actionBtnContainer.layoutIfNeeded()
        groupUserActionView.contentView.layoutIfNeeded()
        groupUserActionView.actionBtnContainer.isHidden = false
        self.groupCellActionView = groupUserActionView
        self.groupCellActionView?.onOutsideViewTapped = {
            [weak self] in
            self?.removeGroupMoreActionView()
        }
        self.groupCellActionView?.onLeaveTapped = { [weak self] in
            self?.showLeaveGroupConfirmation()
        }
        self.groupCellActionView?.onFollowUnfollowTapped = { [ weak self] in
            self?.performFollowUnfollow()
        }
        self.groupCellActionView?.onReportTapped = {
            [weak self] in
            self?.showReportGroupView()
        }
        self.groupCellActionView?.onDeleteTapped = {
            [weak self] in
            self?.showDeleteGroupConfirmation()
        }
        self.groupCellActionView?.onUnhideStoriesTapped = {
            [weak self] in
            self?.tryUnhideGroupStories()
        }
        self.groupCellActionView?.onActivateSubscriptionTapped = {
            [weak self] in
            self?.showActivateGroupSubscriptionConfirmation()

        }
        self.groupCellActionView?.onDeactivateSubscriptionTapped = {
            [weak self] in
            self?.showDeactivateGroupSubscriptionConfirmation()
        }
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.groupCellActionView?.actionBtnContainer.alpha = 1
        } completion: { (true) in
        }
    }
    
    private func showReportGroupView() {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        let reportPopupVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "textEditPopupVC") as! TextEditPopupViewController
        reportPopupVC.modalPresentationStyle = .overFullScreen
        reportPopupVC.shouldAddFullOverlay = true
        reportPopupVC.shouldDismissViewOnTapOutside = false
        reportPopupVC.shouldProceedWithUnchanged = true
        reportPopupVC.contentTitle = AppStrings.Post.Actions.reportGroup
        reportPopupVC.saveBtnTitle = AppStrings.Post.Actions.report
        reportPopupVC.textViewPlaceholder = AppStrings.Post.Actions.reportGroupPlaceholder
        reportPopupVC.contentText = ""
        reportPopupVC.onSave = {
            [weak self] reportText in
            self?.proceedReportGroup(withReportDescription: reportText)
        }
        present(reportPopupVC, animated: true, completion: nil)
    }
    
    private func proceedReportGroup(withReportDescription string: String) {
        self.showOrbisLoader()
        viewModel.reportGroup(withText: string) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.showToastMessage(message: AppStrings.SuccessMessages.groupReported)
            }
            self?.hideOrbisLoader()
        }
    }
    
    func didTapMore(onCell: UITableViewCell, tappedView: UIView) {
        let location = tappedView.convert(tappedView.bounds.origin, to: self.view)
        let locationY = location.y - self.view.safeAreaInsets.top
        showGroupMoreActionView(inLocation: CGPoint(x: location.x - (tappedView.frame.width), y: locationY + tappedView.frame.height), tappedViewFrame: tappedView.bounds)
    }
    
    private func tryUnhideGroupStories() {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryUnhideGroupStories()
    }
    
    private func showActivateGroupSubscriptionConfirmation() {
        self.showConfirmationAlert(title: "", message: AppStrings.Subscription.activateSubscriptionConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) {
            [weak self] (success) in
            if success {
                self?.tryActivateSubscriptions()
            }
        }
    }
    
    private func tryActivateSubscriptions() {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.activateSubscription(completion: { [weak self] result, error in
            if let error = error {
                self?.handleError(error: error)
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    self?.feedTableView.reloadData()
                }
            }
            self?.tryHideLoader()
            
        })
    }
    
    private func showDeactivateGroupSubscriptionConfirmation() {
        self.showConfirmationAlert(title: "", message: AppStrings.Subscription.deactivateSubscriptionConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) {
            [weak self] (success) in
            if success {
                self?.tryDeactivateSubscriptions()
            }
        }
    }
    
    private func tryDeactivateSubscriptions() {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.deactivateSubscription(completion: { [weak self] result, error in
            if let error = error {
                self?.handleError(error: error)
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    self?.feedTableView.reloadData()
                }
            }
            self?.tryHideLoader()
        })
    }
    
    private func showDeleteGroupConfirmation() {
        self.showConfirmationAlert(title: AppStrings.ConfirmationPopup.confirmDeleteGroup, message: AppStrings.ConfirmationPopup.deleteGroupConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) {
            [weak self] (success) in
            if success {
                self?.tryDeleteGroup()
            }
        }
    }
    
    private func tryDeleteGroup() {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryDeleteGroup()
    }
    
    private func showLeaveGroupConfirmation() {
        if viewModel.shouldAssignAdminBeforeLeaving {
            self.showConfirmationAlert(title: AppStrings.ConfirmationPopup.newAdminRequired, message: AppStrings.ConfirmationPopup.newAdminConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] (success) in
                if success {
                    self?.showAssignNewAdminView()
                }
            }
        }
        else {
            self.showConfirmationAlert(title: AppStrings.ConfirmationPopup.confirmLeaveGroup, message: AppStrings.ConfirmationPopup.leaveGroupConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] (success) in
                if success {
                    self?.tryLeaveGroup()
                }
            }
        }
    }
    
    private func tryLeaveGroup() {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryLeaveGroup()
    }
    
    private func showAssignNewAdminView() {
        let membersListVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupMembersListVC") as! GroupMembersListViewController
        membersListVC.viewModel = GroupMembersListViewModel(group: self.viewModel.model)
        membersListVC.groupAdminListDataSource = self
        membersListVC.listType = .newAdminAssign
        membersListVC.onNewAdminSelection = {
            [weak self] user in
            self?.tryAssignNewAdminAndLeaveGroup(user: user)
        }
        self.navigationController?.pushViewController(membersListVC, animated: true)
    }
    
    private func tryAssignNewAdminAndLeaveGroup(user: OrbisUser) {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryAddNewAdminAndLeave(user: user)
    }
    
    private func performFollowUnfollow() {
        if viewModel.isFollower {
            tryUnfollowGroup()
        }
        else {
            tryFollowGroup()
        }
    }
    
    private func tryFollowGroup() {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryFollowGroup()
    }
    
    private func tryUnfollowGroup() {
        self.loaderCount += 1
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryUnfollowGroup()
    }
    
}

extension GroupDetailsViewController: FeedImageFullViewDelegate {
    func didTapImage(at index: Int, inCell cell: UITableViewCell) {
        guard let cellIndex = self.feedTableView.indexPath(for: cell)?.row else { return }
        if let _ = self.feedTableView.cellForRow(at: IndexPath(row: cellIndex, section: 0)) as? EventPostTableViewCell {
            var eventPost: OrbisFeedPost!
            if viewModel.isEventsView {
                eventPost = viewModel.getEventPostModel(at: cellIndex - 2)
            }
            else {
                guard let post = viewModel.getFeedPostModel(at: cellIndex - 2).post else { return }
                eventPost = post
            }
            guard let imageUrls = eventPost.mediaUrls else { return }
            imageFullSizeViewer?.removeFromParent()
            imageFullSizeViewer = nil
            imageFullSizeViewer = (UIStoryboard.getViewController(inStoryboard: "Group", identifier: "orbisImageGalleryVC") as! OrbisImageGalleryViewController)
            imageFullSizeViewer?.storageDirectory = .eventImages
            imageFullSizeViewer?.imagesString = imageUrls
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
        guard let imgPost = viewModel.getFeedPostModel(at: cellIndex - 2).post, imgPost.postType == .imagePost else { return }
        guard let imageNames = imgPost.mediaUrls else { return }
        imageFullSizeViewer?.removeFromParent()
        imageFullSizeViewer = nil
        imageFullSizeViewer = (UIStoryboard.getViewController(inStoryboard: "Group", identifier: "orbisImageGalleryVC") as! OrbisImageGalleryViewController)
        imageFullSizeViewer?.storageDirectory = .postImages
        imageFullSizeViewer?.imagesString = imageNames
        imageFullSizeViewer?.preselectedIndex = index
        imageFullSizeViewer?.modalPresentationStyle = .overCurrentContext
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

extension GroupDetailsViewController: PostCellActionDelegate {
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
        guard let postIndex = self.viewModel.getIndex(for: post), (postIndex == index.row - 2) else { return }
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
    
    private func gotoGroupDetailView(withModel model: Group) {
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: model)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
    
    func didTapGroupName(onCell cell: UITableViewCell, group: Group) {
        guard group.groupKey != self.viewModel.model.groupKey else { return }
        gotoGroupDetailView(withModel: group)
    }
    
    func didTapGroupName(onCell cell: UICollectionViewCell, group: Group) {
        guard group.groupKey != self.viewModel.model.groupKey else { return }
        gotoGroupDetailView(withModel: group)
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

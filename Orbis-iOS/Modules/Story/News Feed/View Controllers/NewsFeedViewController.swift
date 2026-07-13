//
//  NewsFeedViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit
import GoogleMobileAds

//This class represent both My Feed and NearBy
class NewsFeedViewController: OrbisLocalizableViewController {
    @IBOutlet weak var feedTableView: UITableView!
    
    struct NewsFeedCellIdentifier {
        static let storiesCell = "storiesCell"
        static let textPostCell = "textPostCell"
        static let imagePostCell = "imagePostCell"
        static let checkinPostCell = "checkinPostCell"
        static let audioPostCell = "audioPostCell"
        static let videoPostCell = "videoPostCell"
        static let eventPostCell = "eventPostCell"
        static let admobNativeCell = "admobNativeAdCell"
    }
    
    var viewModel: MyFeedViewModel!
    var isFeedLoading: Bool = false
    var isStoriesLoading = false
    weak var cellActionView: PostCellActionView?
    var currentPlayigAudio: AudioPostTableViewCell?
    var currentPlayingVideo: VideoPostTableViewCell?
    var imageFullSizeViewer: OrbisImageGalleryViewController?
    var refreshControl = UIRefreshControl()
    var hasViewFinishedInitialize = false
    var adLoader = AdLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewSetup()
        setupNativeAds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard viewModel.containsStories else { return }
        viewModel.reorderStoriesWRTSeen()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasViewFinishedInitialize else { return }
        hasViewFinishedInitialize = true
        handleViewModelActions()
        addObservers()
        resetData()
        loadFeedData()
        resetStoriesData()
        loadStories()
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
        //MARK: Kamran Khan  code for cache management
        loadFeedData(isUpdated: true)
    }
    
    @objc private func commentCountUpdated(_ notification: NSNotification) {
        guard let countTuple = notification.object as? (String, Int) else { return }
        viewModel.updateCommentCount(key: countTuple.0, count: countTuple.1)
        feedTableView.reloadData()
    }
    
    @objc private func didCompletePendingPost(_ notification: NSNotification) {
        guard let _ = notification.object as? OrbisFeedPost else { return }
        resetData()
        loadFeedData(isUpdated: true)
    }
    
    @objc private func didErrorOccuredInPendingPostCreation(_ notification: NSNotification) {
        guard let object = notification.object as? (Error, OrbisFeedPost) else { return }
        self.handleError(error: object.0)
        resetData()
        loadFeedData()
    }
    
    func tableViewSetup() {
        feedTableView.register(UINib(nibName: "NewsFeedStoriesTVC", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.storiesCell)
        feedTableView.register(UINib(nibName: "ImagePostTableViewCell", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.imagePostCell)
        feedTableView.register(UINib(nibName: "TextPostTableViewCell", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.textPostCell)
        feedTableView.register(UINib(nibName: "AudioPostTableViewCell", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.audioPostCell)
        feedTableView.register(UINib(nibName: "VideoPostTableViewCell", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.videoPostCell)
        feedTableView.register(UINib(nibName: "CheckinPostTableViewCell", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.checkinPostCell)
        feedTableView.register(UINib(nibName: "EventPostTableViewCell", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.eventPostCell)
        feedTableView.register(OrbisViewAttachedTableViewCell.self, forCellReuseIdentifier: "emptyFeedDataCell")
        feedTableView.register(UINib(nibName: "AdmobNativeTableViewCell", bundle: nil), forCellReuseIdentifier: NewsFeedCellIdentifier.admobNativeCell)
        
        feedTableView.dataSource = self
        feedTableView.delegate = self
        
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        feedTableView.addSubview(refreshControl)
    }
    
    private func handleViewModelActions() {
        viewModel.onFeedFetched = { [weak self] in
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.hideOrbisLoader()
                self?.refreshControl.endRefreshing()
                self?.feedTableView.reloadData()
            }
            //data fetched and store in cache
//            if let posts = self?.viewModel.posts {
//                let convertedPosts = CLHelper().toFeedEntities(from: posts, city: Constants.feedCity ?? "", fromNearby: true)
//                //use converted post here
//                self?.viewModel.manageCacheForNewDataInFirstNearBy(feedEntities: convertedPosts, currentCity: Constants.feedCity ?? "")
//
//            } else {
//                print("viewModel.posts is nil")
//            }
        }
        viewModel.onFeedFetchedCompletePagination = { [weak self] in
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.hideOrbisLoader()
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onFeedFetchError = { [weak self] (error) in
            DispatchQueue.main.async {
                [weak self] in
                self?.hideOrbisLoader()
                self?.refreshControl.endRefreshing()
                self?.handleError(error: error)
            }
            self?.isFeedLoading = false
        }
        viewModel.onFeedUpdated = { [weak self] in
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onStoriesFetched = { [weak self] in
            self?.isStoriesLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onStoriesFetchedCompletePagination = { [weak self] in
            self?.isStoriesLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.feedTableView.reloadData()
            }
        }
        viewModel.onStoriesFetchError = { [weak self] (error) in
            DispatchQueue.main.async {
                [weak self] in
                self?.handleError(error: error)
            }
            self?.isStoriesLoading = false
        }
    }
    
    func resetData() {
        viewModel.initializePagination()
        isFeedLoading = false
        feedTableView.reloadData()
    }
    
    func loadFeedData(isUpdated: Bool = false) {
        isFeedLoading = true
        self.showOrbisLoader()
        switch viewModel.type {
        case .nearbyFeed:
            viewModel.loadNearbyFeed(isUpdated: isUpdated)
            break
        case .newsFeed:
            viewModel.loadNewsFeed(isUpdated: isUpdated)
            break
        case .none:
            self.hideOrbisLoader()
        }
    }
    
    func loadMoreFeed() {
        isFeedLoading = true
        self.showOrbisLoader()
        switch viewModel.type {
        case .nearbyFeed:
            viewModel.loadMoreNearbyFeed()
            break
        case .newsFeed:
            viewModel.loadMoreNewsFeed()
            break
        case .none:
            self.hideOrbisLoader()
        }
    }
    
    func resetStoriesData() {
        viewModel.initializeStoriesPagination()
        isStoriesLoading = false
        feedTableView.reloadData()
    }
    
    func loadStories() {
        isStoriesLoading = true
        switch viewModel.type {
        case .nearbyFeed:
            viewModel.loadNearbyStories()
            break
        case .newsFeed:
            viewModel.loadNewsStories()
            break
        case .none:
            break
        }
    }
    
    func loadMoreStories() {
        isStoriesLoading = true
        switch viewModel.type {
        case .nearbyFeed:
            viewModel.loadMoreNearbyStories()
            break
        case .newsFeed:
            viewModel.loadMoreNewsStories()
            break
        case .none:
            break
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshFeed()
    }
    
    func refreshFeed() {
        guard isViewLoaded else {
            return
        }
        resetData()
        loadFeedData(isUpdated: true)
    }

}

extension NewsFeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func getCheckinTableViewCell(at index: Int, tableView: UITableView) -> UITableViewCell {
        let model = viewModel.getPostModel(at: index)
        guard model.feedPostType == .slider else { return UITableViewCell(frame: .zero) }
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.checkinPostCell) as! CheckinPostTableViewCell
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
    
    private func getNativeAdCell(at index: Int, tableView: UITableView) -> UITableViewCell {
        let model = viewModel.getPostModel(at: index)
        guard model.feedPostType == .nativeAd, let ad = model.ad else { return UITableViewCell(frame: .zero) }
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.admobNativeCell) as! AdmobNativeTableViewCell
        cell.fill(adMob: ad)
        cell.removeExistingLoadingOverlay()
        return cell
    }
    
    private func getPostTableViewCell(ofType type: OrbisPostType, tableView: UITableView, atIndex index: Int) -> UITableViewCell {
        let model = viewModel.getPostModel(at: index)
        guard model.feedPostType == .post else { return UITableViewCell(frame: .zero) }
        switch type {
        case .textPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.textPostCell) as! TextPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.imagePostCell) as! ImagePostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.audioPostCell) as! AudioPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.eventPostCell) as! EventPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.videoPostCell) as! VideoPostTableViewCell
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
        if viewModel.containsStories {
            if indexPath.row == 0 {
                // load stories
                let storyCell = tableView.dequeueReusableCell(withIdentifier: NewsFeedCellIdentifier.storiesCell) as! NewsFeedStoriesTVC
                storyCell.storyCellTapResponseDelegate = self
                storyCell.viewModel = FeedStoriesViewModel(model: viewModel.stories)
                storyCell.storiesCollectionView.reloadData()
                return storyCell
            }
            guard viewModel.hasFeedPosts else {
                if isFeedLoading {
                    return UITableViewCell(frame: .zero)
                }
                let emptyCell = tableView.dequeueReusableCell(withIdentifier: "emptyFeedDataCell") as! OrbisViewAttachedTableViewCell
                let emptyContentView = EmptyDataContentView(description: AppErrorStrings.feedEmpty, image: #imageLiteral(resourceName: "profile-no-photos-ic"), imageSize: CGSize(width: 207, height: 168), contentPadding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), backgroundColor: .clear)
                emptyContentView.layoutIfNeeded()
                emptyCell.addContent(view: emptyContentView)
                emptyCell.attachedView.layoutIfNeeded()
                emptyCell.layoutIfNeeded()
                return emptyCell
            }
            let model = viewModel.getPostModel(at: indexPath.row - 1)
            switch model.feedPostType {
            case .slider:
                return getCheckinTableViewCell(at: indexPath.row - 1, tableView: tableView)
            case .post:
                let type = model.post?.postType ?? .checkinPost
                return getPostTableViewCell(ofType: type, tableView: tableView, atIndex: indexPath.row -  1)
            case .nativeAd:
                return getNativeAdCell(at: indexPath.row - 1, tableView: tableView)
            }
        }
        else {
            guard viewModel.hasFeedPosts else {
                if isFeedLoading {
                    return UITableViewCell(frame: .zero)
                }
                let emptyCell = tableView.dequeueReusableCell(withIdentifier: "emptyFeedDataCell") as! OrbisViewAttachedTableViewCell
                let emptyContentView = EmptyDataContentView(description: AppErrorStrings.newsFeedEmpty, image: #imageLiteral(resourceName: "profile-no-photos-ic"), imageSize: CGSize(width: 207, height: 168), contentPadding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), backgroundColor: .clear)
                emptyContentView.layoutIfNeeded()
                emptyCell.addContent(view: emptyContentView)
                emptyCell.attachedView.layoutIfNeeded()
                emptyCell.layoutIfNeeded()
                return emptyCell
            }
            let model = viewModel.getPostModel(at: indexPath.row)
            switch model.feedPostType {
            case .slider:
                return getCheckinTableViewCell(at: indexPath.row, tableView: tableView)
            case .post:
                let type = model.post?.postType ?? .checkinPost
                return getPostTableViewCell(ofType: type, tableView: tableView, atIndex: indexPath.row)
            case .nativeAd:
                return getNativeAdCell(at: indexPath.row, tableView: tableView)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.containsStories && indexPath.row == 0 {
            return 85.toCGFloat.relativeToIphone8Width()
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
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
        guard indexPath.row > 5 else {
            return
        }
        if viewModel.containsStories {
            let model = viewModel.getPostModel(at: indexPath.row - 1)
            if model.feedPostType == .nativeAd && viewModel.shouldFetchMoreAds {
                loadAds()
            }
        }
        else {
            let model = viewModel.getPostModel(at: indexPath.row)
            if model.feedPostType == .nativeAd && viewModel.shouldFetchMoreAds {
                loadAds()
            }
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
        if viewModel.containsStories {
            guard indexPath.row > 0 else { return }
            let model = viewModel.getPostModel(at: indexPath.row - 1)
            guard model.post?.postType == .eventPost, let event = model.post else { return }
            showEventDetailsView(event: event)
        }
        else {
            let model = viewModel.getPostModel(at: indexPath.row)
            guard model.post?.postType == .eventPost, let event = model.post else { return }
            showEventDetailsView(event: event)
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
    
}

extension NewsFeedViewController: StoryItemTapResponseDelegate {
    
    private func unfollowGroupStories(atIndex index: Int) {
        self.showOrbisLoader(disableUserInteraction: true)
        self.viewModel.unfollowGroupStories(at: index) { [weak self] result, error in
            if let error = error {
                self?.handleError(error: error)
            }
            else {
                if let success = result as? Bool, success {
                    self?.feedTableView.reloadData()
                }
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func showStoryGroupActionSheet(atIndex index: Int) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let unfollowStoriesAction = UIAlertAction(title: AppStrings.Feed.unfollowGroupStories, style: .default) { [weak self] _ in
            self?.unfollowGroupStories(atIndex: index)
        }
        let cancelAction = UIAlertAction(title: AppStrings.cancel.capitalized, style: .cancel)
        alertController.addAction(unfollowStoriesAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func didLongTapStoryCell(atIndex index: Int) {
        guard viewModel.type == .newsFeed else { return }
        showStoryGroupActionSheet(atIndex: index)
    }
    
    func didTriggerPagination() {
        if !isStoriesLoading && !viewModel.hasStoriesItemsLastPageReached {
            loadMoreStories()
        }
    }
    
    func didTapStoryCell(atIndex index: Int) {
        let stories = self.viewModel.stories
        let unseenStoryIndex = self.viewModel.stories[index].posts.firstIndex(where: {$0.seen == false}) ?? 0
        let storyPreviewScene = OrbisStoryPreviewController.init(stories: stories, handPickedStoryIndex:  index, handPickedSnapIndex: unseenStoryIndex)
        storyPreviewScene.storyActionDelegate = self
        let storyNavVC = OrbisNavigationController(rootViewController: storyPreviewScene)
        storyNavVC.modalPresentationStyle = .overCurrentContext
        self.present(storyNavVC, animated: true, completion: nil)
    }
}

extension NewsFeedViewController: PostCellActionDelegate {
    
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
        guard let postIndex = self.viewModel.getIndex(for: post), postIndex == (index.row - 1) else { return }
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
        self.feedTableView.reloadRows(at: [index], with: .none)
        feedTableView.endUpdates()
    }
    
    func didTapViewMore(onCell: UICollectionViewCell, post: OrbisFeedPost,  maxLines: Int) {
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
        let profileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        if user.deleted == true {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
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
        gotoGroupDetailView(withModel: group)
    }
    
    func didTapGroupName(onCell cell: UICollectionViewCell, group: Group) {
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
        self.cellActionView?.onReportTapped = { [weak self] in
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


extension NewsFeedViewController: FeedImageFullViewDelegate {
    func didTapImage(at index: Int, inCell cell: UITableViewCell) {
        guard let cellIndex = self.feedTableView.indexPath(for: cell)?.row else { return }
        if viewModel.containsStories {
            guard let imgPost = viewModel.getPostModel(at: cellIndex - 1).post else { return }
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
        else {
            guard let imgPost = viewModel.getPostModel(at: cellIndex).post else { return }
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
}

extension NewsFeedViewController: OrbisStoryActionDelegate {
    func didSeenStory(key: String) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        viewModel.markStorySeen(key: key)
    }
    
    func didDismissStoryPreview() {
        guard viewModel.containsStories else { return }
        viewModel.reorderStoriesWRTSeen()
    }
}

extension NewsFeedViewController: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard viewModel != nil else { return }
        viewModel.nativeAds.append(nativeAd)
        viewModel.appendAdsIfNecessary()
        self.feedTableView.reloadData()
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        debugPrint("Native Ads could not load: \(error.localizedDescription)")
    }
    
    func setupNativeAds() {
        let options = MultipleAdsAdLoaderOptions()
        options.numberOfAds = 2

        adLoader = AdLoader(adUnitID: APPKeys.Admob.nativeAdUnitKey,
                            rootViewController: self,
                            adTypes: [.native],
                            options: [options])
        adLoader.delegate = self
        
        loadAds()
    }
    
    func loadAds() {
        adLoader.load(Request())
    }
}

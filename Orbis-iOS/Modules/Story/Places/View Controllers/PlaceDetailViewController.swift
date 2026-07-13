//
//  PlaceDetailViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import UIKit
import MapKit
import ExpandableLabel
import HWPanModal

class PlaceDetailViewController: OrbisLocalizableViewController {

    @IBOutlet weak var placeDetailTableView: UITableView!
    
    @IBOutlet weak var eventsAddNewBtnView: RoundedView!
    @IBOutlet weak var placeCreatePostBtnView: RoundedView!
    @IBOutlet weak var placeGotoEventBtnView: RoundedView!
    @IBOutlet weak var eventGotoPlaceBtnView: RoundedView!
    @IBOutlet weak var placePostCheckinIconView: UIImageView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func eventBtnTapped(_ sender: Any) {
        showEventListView()
    }
    
    @IBAction func placeFeedBtnTapped(_ sender: Any) {
        showPlaceFeedListView()
    }
    @IBAction func eventAddNewBtnTapped(_ sender: Any) {
        showCreateEventPage()
    }
    @IBAction func placeCreatePostBtnTapped(_ sender: Any) {
        showCreatePostPage()
    }
    
    struct PlaceFeedCellIdentifier {
        static let placeHeaderCell = "placeHeaderCell"
        static let placeNearbyGroupsCell = "placeNearbyGroupsCell"
        static let eventCellTitleCell = "eventTitleCell"
        static let textPostCell = "textPostCell"
        static let imagePostCell = "imagePostCell"
        static let checkinPostCell = "checkinPostCell"
        static let audioPostCell = "audioPostCell"
        static let videoPostCell = "videoPostCell"
        static let eventPostCell = "eventPostCell"
    }
    
    var viewModel: PlaceDetailViewModel!
    weak var cellActionView: PostCellActionView?
    var hasDataLoaded: Bool = false
    var loaderCount = 0
    var isFeedLoading: Bool = false
    var isEventLoading = false
    var refreshControl = UIRefreshControl()
    var currentPlayigAudio: AudioPostTableViewCell?
    var currentPlayingVideo: VideoPostTableViewCell?
    
    weak var proPicActionView: ProfilePicActionView?
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    var imageFullSizeViewer: OrbisImageGalleryViewController?
    
    var headerCollapseState: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewScene()
        tableViewSetup()
        handleViewModelActions()
        addObservers()
        syncData()
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
        placeDetailTableView.reloadData()
    }
    
    @objc private func didCompletePendingPost(_ notification: NSNotification) {
        guard let object = notification.object as? OrbisFeedPost, object.place?.placeKey == self.viewModel.model.placeKey else { return }
        resetData()
        loadFeedData()
    }
    
    @objc private func didErrorOccuredInPendingPostCreation(_ notification: NSNotification) {
        guard let object = notification.object as? (Error, OrbisFeedPost), object.1.place?.placeKey == self.viewModel.model.placeKey else { return }
        self.handleError(error: object.0)
        resetData()
        loadFeedData()
    }
    
    private func handleViewModelActions() {
        viewModel.onPlaceDetailSyncError = {
            [weak self] error in
            self?.refreshControl.endRefreshing()
            self?.handleError(error: error)
            self?.tryHideLoader()
        }
        viewModel.onPlaceDetailSyncSuccess = {
            [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.updateViewScene()
            self?.hasDataLoaded = true
            DispatchQueue.main.async {
                [weak self] in
                self?.placeDetailTableView.reloadData()
            }
        }
        viewModel.onPlaceDetailUpdateError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.tryHideLoader()
        }
        viewModel.onPlaceDetailUpdateSuccess = {
            [weak self] in
            self?.tryHideLoader()
            self?.updateViewScene()
            DispatchQueue.main.async {
                [weak self] in
                self?.placeDetailTableView.reloadData()
            }
        }
        viewModel.onPlaceFeedFetched = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.placeDetailTableView.reloadData()
            }
        }
        viewModel.onPlaceFeedFetchedCompletePagination = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isFeedLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.placeDetailTableView.reloadData()
            }
        }
        viewModel.onPlaceFeedFetchError = { [weak self] (error) in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.handleError(error: error)
            self?.isFeedLoading = false
        }
        viewModel.onPostUpdated = {
            [weak self] in
            DispatchQueue.main.async {
                [weak self] in
                self?.placeDetailTableView.reloadData()
            }
        }
        viewModel.onEventFeedFetched = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isEventLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.placeDetailTableView.reloadData()
            }
        }
        viewModel.onEventFeedFetchedCompletePagination = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tryHideLoader()
            self?.isEventLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.placeDetailTableView.reloadData()
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
                self?.placeDetailTableView.reloadData()
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
        viewModel.syncPlaceDataWithServer()
    }
    
    func resetData() {
        viewModel.initializePagination()
        isFeedLoading = false
        placeDetailTableView.reloadData()
    }
    
    func loadFeedData() {
        isFeedLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadPlaceFeed()
    }
    
    func loadMoreFeed() {
        isFeedLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadMorePlaceFeed()
    }
    
    func resetEventData() {
        viewModel.initializeEventsPagination()
        isEventLoading = false
        placeDetailTableView.reloadData()
    }
    
    func loadEventData() {
        isEventLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadPlaceEvents()
    }
    
    func loadMoreEvent() {
        isEventLoading = true
        self.loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadMorePlaceEvents()
    }
    
    func tableViewSetup() {
        placeDetailTableView.register(UINib(nibName: "PlaceHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.placeHeaderCell)
        placeDetailTableView.register(UINib(nibName: "GroupsNearbyTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.placeNearbyGroupsCell)
        placeDetailTableView.register(UINib(nibName: "FeedTitleTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.eventCellTitleCell)
        placeDetailTableView.register(UINib(nibName: "ImagePostTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.imagePostCell)
        placeDetailTableView.register(UINib(nibName: "TextPostTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.textPostCell)
        placeDetailTableView.register(UINib(nibName: "AudioPostTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.audioPostCell)
        placeDetailTableView.register(UINib(nibName: "VideoPostTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.videoPostCell)
        placeDetailTableView.register(UINib(nibName: "CheckinPostTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.checkinPostCell)
        placeDetailTableView.register(UINib(nibName: "EventPostTableViewCell", bundle: nil), forCellReuseIdentifier: PlaceFeedCellIdentifier.eventPostCell)
        placeDetailTableView.register(OrbisViewAttachedTableViewCell.self, forCellReuseIdentifier: "emptyFeedDataCell")
        
        placeDetailTableView.dataSource = self
        placeDetailTableView.delegate = self
        placeDetailTableView.reloadData()
        
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        placeDetailTableView.addSubview(refreshControl)
    }
    
    private func updateViewScene() {
        let isEventsView = viewModel.isEventsView
        eventsAddNewBtnView.isHidden = !isEventsView
        eventGotoPlaceBtnView.isHidden = !isEventsView
        placeGotoEventBtnView.isHidden = isEventsView
        placeCreatePostBtnView.isHidden = isEventsView
        UIView.transition(with: placeDetailTableView, duration: 0.5, options: [.curveEaseInOut, .transitionCrossDissolve], animations: {
                            self.placeDetailTableView.reloadData()},
                          completion: nil)
        let addIcon = #imageLiteral(resourceName: "add-new-ic")
        let checkinAddIcon = #imageLiteral(resourceName: "add-checkin-ic")
        placePostCheckinIconView.image = viewModel.placeDistance > 1 ? addIcon : checkinAddIcon
    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshFeed()
    }
    
    private func refreshFeed() {
        refreshControl.endRefreshing()
        syncData()
        updateViewScene()
        if viewModel.isEventsView {
            resetEventData()
            loadEventData()
        }
        else {
            resetData()
            loadFeedData()
        }
    }
    
    private func showEventListView() {
        viewModel.isEventsView = true
        updateViewScene()
        if !viewModel.hasFeedPosts {
            resetEventData()
            loadEventData()
        }
    }
    
    private func showPlaceFeedListView() {
        viewModel.isEventsView = false
        updateViewScene()
        if !viewModel.hasFeedPosts {
            resetData()
            loadFeedData()
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

    private func showCreatePostPage() {
        guard viewModel.isLoggedIn else {
            gotoAuthView()
            return
        }
        let createPostVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "createPostVC") as! CreatePostViewController
        createPostVC.modalPresentationStyle = .overFullScreen
        createPostVC.viewModel = CreatePostViewModel(defaultPublisherGroup: viewModel.model.dominantGroup ?? viewModel.model.competingGroups?.first, isSelfPublisher: false, selectedPlace: viewModel.model)
        createPostVC.createPostInvoker = CreatePostInvoker.place
        createPostVC.shouldDisablePlaceSelection = true
        createPostVC.defaultPostType = viewModel.placeDistance <= 1 ? .checkinPost : .textPost
        createPostVC.restrictPage = true
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
        presentPanModal(createPostVC)
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
        place.checkInPolygonCoordinateKey = post.checkInPolygonCoordinateKey
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            self.navigationController?.popToRootViewController(animated: true)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                homeVC.handlePlaceCheckinSuccess(place: place)
            }
        }
    }
    
    private func showCreateEventPage() {
        guard viewModel.isLoggedIn else {
            gotoAuthView()
            return
        }
        let createEventVC = UIStoryboard.getViewController(inStoryboard: "Events", identifier: "createEventVC") as! CreateEventViewController
        createEventVC.viewModel = CreatePostViewModel(defaultPublisherGroup: viewModel.model.dominantGroup ?? viewModel.model.competingGroups?.first, isSelfPublisher: false, selectedPlace: viewModel.model)
        createEventVC.shouldDisablePlaceSelection = true
        createEventVC.modalPresentationStyle = .overFullScreen
        createEventVC.onCreatePostSuccess = {
            [weak self] data in
            self?.refreshFeed()
        }
        presentPanModal(createEventVC)
    }
    
    private func showEditDescriptionView() {
        let textEditPopupVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "textEditPopupVC") as! TextEditPopupViewController
        textEditPopupVC.modalPresentationStyle = .overFullScreen
        textEditPopupVC.shouldAddFullOverlay = true
        textEditPopupVC.shouldDismissViewOnTapOutside = false
        textEditPopupVC.contentTitle = AppStrings.Places.editPlaceDescription
        textEditPopupVC.contentText = viewModel.model.description ?? ""
        textEditPopupVC.onSave = {
            [weak self] newDescription in
            self?.tryChangeDescription(withText: newDescription)
        }
        present(textEditPopupVC, animated: true, completion: nil)
    }
    
    private func showPlaceInfoPopupView(type: PlaceInfoPopupViewType) {
        let model = viewModel.model!
        var isFieldEmpty = false
        switch type {
        case .address:
            isFieldEmpty = (model.address ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .telephone:
            isFieldEmpty = (model.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .schedule:
            isFieldEmpty = (model.workingHours ?? []).count == 0
        case .website:
            isFieldEmpty = (model.website ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if isFieldEmpty && !viewModel.isLoggedIn {
            gotoAuthView()
            return
        }
        let vc = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeInfoPopupVC") as! PlaceInfoViewPopupVC
        vc.modalPresentationStyle = .overCurrentContext
        vc.viewModel = PlaceInfoPopupViewModel(viewType: type, model: model)
        vc.onContentUpdated = {
            [weak self] updatedModel in
            guard updatedModel.placeKey == self?.viewModel.model.placeKey else { return }
            self?.viewModel.model = updatedModel
        }
        presentPanModal(vc)
    }
    
    private func showPlaceReviewPopupView() {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        let vc = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeReviewPopupVC") as! PlaceRatePopupVC
        vc.modalPresentationStyle = .overCurrentContext
        vc.viewModel = PlaceRatePopupViewModel(place: viewModel.model)
        vc.onPlaceRated = {
            [weak self] in
            self?.syncData()
        }
        presentPanModal(vc)
    }
    
    private func tryChangeDescription(withText text: String) {
        self.loaderCount += 1
        self.view.showOrbisLoader()
        viewModel.updatePlaceDescription(withText: text)
    }
    
    private func tryChangePlacePhoto(image: UIImage) {
        self.loaderCount += 1
        self.view.showOrbisLoader()
        viewModel.uploadPlacePicture(image: image)
    }
    
    private func showPlaceMoreActions() {
        let actionSheetVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: AppStrings.Post.Actions.report, style: .default) { [weak self] action in
            self?.showReportPlaceView()
        }
        let cancelAction = UIAlertAction(title: AppStrings.cancel, style: .destructive, handler: nil)
        actionSheetVC.addAction(reportAction)
        actionSheetVC.addAction(cancelAction)
        self.present(actionSheetVC, animated: true, completion: nil)
    }
    
    private func showReportPlaceView() {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        let reportPopupVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "textEditPopupVC") as! TextEditPopupViewController
        reportPopupVC.modalPresentationStyle = .overFullScreen
        reportPopupVC.shouldAddFullOverlay = true
        reportPopupVC.shouldDismissViewOnTapOutside = false
        reportPopupVC.shouldProceedWithUnchanged = true
        reportPopupVC.contentTitle = AppStrings.Post.Actions.reportPlace
        reportPopupVC.saveBtnTitle = AppStrings.Post.Actions.report
        reportPopupVC.textViewPlaceholder = AppStrings.Post.Actions.reportPlacePlaceholder
        reportPopupVC.contentText = ""
        reportPopupVC.onSave = {
            [weak self] reportText in
            self?.proceedReportPlace(withReportDescription: reportText)
        }
        present(reportPopupVC, animated: true, completion: nil)
    }
    
    private func proceedReportPlace(withReportDescription string: String) {
        self.showOrbisLoader()
        viewModel.reportPlace(withText: string) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.showToastMessage(message: AppStrings.SuccessMessages.placeReported)
            }
            self?.hideOrbisLoader()
        }
    }
}

extension PlaceDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func getCheckinTableViewCell(at index: Int, tableView: UITableView) -> UITableViewCell {
        let model = viewModel.getFeedPostModel(at: index)
        guard model.feedPostType == .slider else { return UITableViewCell(frame: .zero) }
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.checkinPostCell) as! CheckinPostTableViewCell
        cell.isPlaceCheckinCell = true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.eventPostCell) as! EventPostTableViewCell
        let cellViewModel = EventPostCellViewModel(data: model)
        cell.viewModel = cellViewModel
        cell.actionDelegate = self
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
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.textPostCell) as! TextPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.imagePostCell) as! ImagePostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.audioPostCell) as! AudioPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.eventPostCell) as! EventPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.videoPostCell) as! VideoPostTableViewCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.placeHeaderCell) as! PlaceHeaderTableViewCell
            cell.placeDescriptionLabel.delegate = self
            let linkFont = UIFont(name: "Roboto-Black", size: CGFloat(16).relativeToIphone8Width())!
            cell.placeDescriptionLabel.setLessLinkWith(lessLink: AppStrings.viewLess, attributes: [
                .foregroundColor:UIColor(named: AppColors.appBlue.rawValue)!,
                .font: linkFont
            ], position: .left)
            cell.placeDescriptionLabel.collapsedAttributedLink = NSAttributedString(string: AppStrings.viewMore, attributes: [
                .foregroundColor:UIColor(named: AppColors.appBlue.rawValue)!,
                .font: linkFont
            ])
            cell.layoutIfNeeded()
            cell.placeDescriptionLabel.shouldCollapse = true
            cell.placeDescriptionLabel.numberOfLines = 3
            cell.placeDescriptionLabel.collapsed = headerCollapseState
            cell.viewModel = PlaceHeaderCellViewModel(place: viewModel.model, description: viewModel.placeDescription)
            cell.headerContentChangeDelegate = self
            cell.onMoreTapped = {
                [weak self] in
                self?.showPlaceMoreActions()
            }
            cell.onAddressSvTapped = {
                [weak self] in
                self?.showPlaceInfoPopupView(type: .address)
            }
            cell.onTelephoneSvTapped = {
                [weak self] in
                self?.showPlaceInfoPopupView(type: .telephone)
            }
            cell.onWebsiteSvTapped = {
                [weak self] in
                self?.showPlaceInfoPopupView(type: .website)
            }
            cell.onScheduleSvTapped = {
                [weak self] in
                self?.showPlaceInfoPopupView(type: .schedule)
            }
            cell.onReviewTapped = {
                [weak self] in
                self?.showPlaceReviewPopupView()
            }
            return cell
        }
        if indexPath.row == 1 {
            if viewModel.isEventsView {
                // load event title cell
                let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.eventCellTitleCell) as! FeedTitleTableViewCell
                cell.titleLabel.text = AppStrings.Events.events
                return cell
            }
            else {
                // load nearby groups
                let cell = tableView.dequeueReusableCell(withIdentifier: PlaceFeedCellIdentifier.placeNearbyGroupsCell) as! GroupsNearbyTableViewCell
                cell.viewModel = PlaceNearbyGroupsCellViewModel(groups: viewModel.nearbyGroups)
                cell.actionDelegate = self
                cell.layoutIfNeeded()
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
            let emptyContentView = EmptyDataContentView(description: AppErrorStrings.placeFeedEmpty, image: #imageLiteral(resourceName: "profile-no-photos-ic"), imageSize: CGSize(width: 207, height: 168), contentPadding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), backgroundColor: .clear)
            emptyContentView.layoutIfNeeded()
            emptyCell.addContent(view: emptyContentView)
            emptyCell.attachedView.layoutIfNeeded()
            emptyCell.layoutIfNeeded()
            return emptyCell
        }
        if viewModel.isEventsView {
            return getEventPostTableViewCell(tableView: tableView, atIndex: indexPath.row - 2)
        }
        else {
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
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
}

extension PlaceDetailViewController: NearByGroupActionDelegate {
    func didSelectGroup(at index: Int) {
        let group = viewModel.nearbyGroups[index]
        gotoGroupDetailView(withModel: group)
    }
    
    private func gotoGroupDetailView(withModel model: Group) {
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: model)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
}

extension PlaceDetailViewController: PostCellActionDelegate {
    
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
        guard let index = self.placeDetailTableView.indexPath(for: onCell) else { return }
        guard let postIndex = self.viewModel.getIndex(for: post), (postIndex == index.row - 2) else { return }
        viewModel.replaceExpandedPost(expandedPost: post)
        placeDetailTableView.beginUpdates()
        let point = onCell.convert(CGPoint.zero, to: placeDetailTableView)
        if let indexPath = placeDetailTableView.indexPathForRow(at: point) as IndexPath? {
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
                    self?.placeDetailTableView.scrollToRow(at: indexPath, at: .top, animated: false)
                }
            }
        }
        placeDetailTableView.reloadRows(at: [index], with: .none)
        placeDetailTableView.endUpdates()
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
    
    func didTapGroupName(onCell cell: UITableViewCell, group: Group) {
        gotoGroupDetailView(withModel: group)
    }
    
    func didTapGroupName(onCell cell: UICollectionViewCell, group: Group) {
        gotoGroupDetailView(withModel: group)
    }
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        guard self.viewModel.model.placeKey != place.placeKey else { return }
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

extension PlaceDetailViewController: OrbisViewHeaderContentChangeDelegate {
    func followUnfollowTapped(imageView: UIImageView) {
        guard !viewModel.isFollowUnfollowProcessing else { return }
        imageView.showOrbisLoader(withSize: imageView.frame.width, clearBackground: false, useFullScreen: false)
        viewModel.followUnfollow { [weak self] data, err in
            DispatchQueue.main.async {
                [weak self] in
                imageView.hideOrbisLoader()
                self?.placeDetailTableView.reloadData()
            }
        }
    }
    
    
    private func removePropicActionView() {
        proPicActionView?.removeFromSuperview()
        proPicActionView = nil
    }
    
    private func setupImagePickerView() {
        config = YPImagePicker.getAppImageViewConfig()
        imagePickerController = YPImagePicker(configuration: config)
        imagePickerController.didFinishPicking { [weak self] (items, success) in
            guard let strongSelf = self else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            if let photo = items.singlePhoto {
                let img = photo.modifiedImage ?? photo.originalImage
//                let reducedImageData = img.jpegData(compressionQuality: 0.6) ?? imageData
                // upload photo
                strongSelf.tryChangePlacePhoto(image: img)
            }
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    func openImagePickerView() {
        setupImagePickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func showProPicActionView(inLocation point: CGPoint) {
        removePropicActionView()
        let proPicActionView = ProfilePicActionView(frame: self.view.bounds)
        proPicActionView.actionBtnContainer.alpha = 0
        proPicActionView.secondButtonView.alpha = 0
        self.view.addSubview(proPicActionView)
        proPicActionView.translatesAutoresizingMaskIntoConstraints = false
        proPicActionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        proPicActionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        proPicActionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        proPicActionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.view.bringSubviewToFront(proPicActionView)
        proPicActionView.btnTopConstraint.constant = point.y
        proPicActionView.btnLeadingConstraint.constant = point.x
        proPicActionView.actionBtnContainer.layoutIfNeeded()
        proPicActionView.secondButtonView.layoutIfNeeded()
        proPicActionView.contentView.layoutIfNeeded()
        proPicActionView.hideSecondaryButton = false
        proPicActionView.actionBtnContainer.isHidden = false
        self.proPicActionView = proPicActionView
        self.proPicActionView?.onOutsideViewTapped = {
            [weak self] in
            self?.removePropicActionView()
        }
        self.proPicActionView?.onActionBtnTapped = {
            [weak self] in
            self?.openImagePickerView()
            self?.removePropicActionView()
        }
        self.proPicActionView?.onSecondaryActionBtnTapped = {
            [weak self] in
            self?.gotoExternalMapsApp()
            self?.removePropicActionView()
        }
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.proPicActionView?.actionBtnContainer.alpha = 1
            self?.proPicActionView?.secondButtonView.alpha = 1
        } completion: { (true) in
        }
    }
    
    
    func showUploadPhotoPopup(view: UIView) {
        let location = view.convert(view.frame.origin, to: self.view)
        let locationY = location.y - self.view.safeAreaInsets.top
        showProPicActionView(inLocation: CGPoint(x: location.x + (view.frame.width * 0.3), y: locationY + (view.frame.height * 0.5)))
    }
    
    func pictureViewTapped(view: UIView) {
        showUploadPhotoPopup(view: view)
    }
    
    func descriptionTapped(view: UIView) {
        guard viewModel.canEditPlace else { return }
        showEditDescriptionView()
    }
    
    private func gotoExternalMapsApp() {
        guard let placeLocation = viewModel.model.coordinates, let placeLat = placeLocation.latitude, let placeLong = placeLocation.longitude else { return }
        if let userCurrentLocation = UserSessionManager.shared.userCurrentLocation {
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                if let url = URL(string: "comgooglemaps-x-callback://?saddr=\(userCurrentLocation.latitude),\(userCurrentLocation.longitude)&daddr=\(placeLat),\(placeLong)&directionsmode=driving") {
                    UIApplication.shared.open(url, options: [:])
                }}
            else {
                var sourceName = "Source"
                if let name = UserSessionManager.shared.currentUser?.name {
                    sourceName = name + "\'s place"
                }
                let source = MKMapItem(coordinate: .init(latitude: userCurrentLocation.latitude, longitude: userCurrentLocation.longitude), name: sourceName)
                let destination = MKMapItem(coordinate: .init(latitude: placeLat, longitude: placeLong), name: viewModel.model.name ?? "Destination")
                MKMapItem.openMaps(
                  with: [source, destination],
                  launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault]
                )
            }
        }
        else {
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(placeLat),\(placeLong)&directionsmode=driving") {
                    UIApplication.shared.open(url, options: [:])
                }}
            else {
                let destination = MKMapItem(coordinate: .init(latitude: placeLat, longitude: placeLong), name: viewModel.model.name ?? "Destination")
                MKMapItem.openMaps(
                  with: [destination],
                  launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault]
                )
            }
        }
    }
}

extension PlaceDetailViewController: FeedImageFullViewDelegate {
    func didTapImage(at index: Int, inCell cell: UITableViewCell) {
        guard let cellIndex = self.placeDetailTableView.indexPath(for: cell)?.row else { return }
        if let _ = self.placeDetailTableView.cellForRow(at: IndexPath(row: cellIndex, section: 0)) as? EventPostTableViewCell {
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

extension PlaceDetailViewController: ExpandableLabelDelegate {
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        self.placeDetailTableView.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: placeDetailTableView)
        if let indexPath = placeDetailTableView.indexPathForRow(at: point) as IndexPath? {
            headerCollapseState = false
            DispatchQueue.main.async { [weak self] in
                self?.placeDetailTableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        placeDetailTableView.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        placeDetailTableView.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: placeDetailTableView)
        if let indexPath = placeDetailTableView.indexPathForRow(at: point) as IndexPath? {
            headerCollapseState = true
            DispatchQueue.main.async { [weak self] in
                self?.placeDetailTableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        placeDetailTableView.endUpdates()
    }
}

//
//  UserProfileViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/04/2021.
//

import UIKit

enum ProfileTab: String {
    case photos
    case posts
    case none
}

protocol OrbisParallexScrollDelegate: AnyObject {
    func didChangeChildScrollView(scrollView: UIScrollView?)
    func childScrollViewDidScroll(_ scrollView: UIScrollView)
    func profileDidChangeTab(tab: ProfileTab)
    func getCurrentSelectedTabIndex() -> Int
    func openFullSizeImage(imageView: UIImageView, data: UserProfileMedia)
    func showCommonLoader()
    func hideCommonLoader()
    func getParentViewController() -> UIViewController
}

class UserProfileViewController: OrbisLocalizableViewController{
    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var addPhotosBtnView: RoundedView!
    @IBOutlet weak var addNewBtnView: RoundedView!
    @IBOutlet weak var searchUserBtnView: RoundedView!
    @IBOutlet weak var otherUserMessageBtnView: RoundedView!
    @IBOutlet weak var otherUserRightSearchBtnView: RoundedView!
    
    weak var childScrollView: UIScrollView?
    weak var proPicActionView: ProfilePicActionView?
    var currentSelectionIndex: Int = 0
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addNewTapped(_ sender: Any) {
        tryOpenCreatePostView()
    }
    @IBAction func addPhotosTapped(_ sender: Any) {
        openProfilePhotosPickerView()
    }
    @IBAction func searchTapped(_ sender: Any) {
        gotoSearchUser()
    }
    @IBAction func otherUserBottomSearchTapped(_ sender: Any) {
        gotoSearchUser()
    }
    @IBAction func otherUserMessageTapped(_ sender: Any) {
        createConversationIfNeeded(withUser: viewModel.user)
    }
    
    var viewModel: ProfileDetailViewModel!
    
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    
    var imageFullSizeViewer: OrbisImageGalleryViewController?
    
    var profilePhotosPickerConfig: YPImagePickerConfiguration!
    var profilePhotosPickerController: YPImagePicker!
    
    var goingUp: Bool?
    var childScrollingDownDueToParent = false
    
    var hasDataLoaded: Bool = false
    var isFetchingUnreadMessages = false
    var loaderCount = 0
    var isProfileSynching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewSetup()
        handleViewModelActions()
        updateBottomStackComponents(forTab: .none)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isProfileSynching else { return }
        isProfileSynching = true
        syncData()
    }
    
    func tableViewSetup() {
        profileTableView.register(UINib(nibName: "ProfileTableHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: "profileHeaderCell")
        profileTableView.register(UINib(nibName: "OtherUserProfileHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: "otherUserProfileHeaderCell")
        profileTableView.dataSource = self
        profileTableView.delegate = self
        self.loaderCount = 0
        tryHideLoader()
        profileTableView.reloadData()
    }
    
    private func handleViewModelActions() {
        viewModel.onUserDetailSyncError = {
            [weak self] error in
            self?.tryHideLoader()
            self?.isProfileSynching = false
            DispatchQueue.main.async {
                [weak self] in
                self?.handleError(error: error)
            }
        }
        viewModel.onUserDetailSyncSuccess = {
            [weak self] in
            self?.hasDataLoaded = true
            self?.isProfileSynching = false
            self?.tryHideLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.updateBottomStackComponents(forTab: .none)
                self?.loaderCount = 0
                self?.tryHideLoader()
                self?.profileTableView.reloadData()
//                if let _ = self?.profileTableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? PrivateProfileLockTableViewCell {
//                    self?.profileTableView.reloadData()
//                }
//                else {
//                    self?.profileTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
//                }
            }
        }
        viewModel.onUserBlockedTrue = {
            [weak self] in
            self?.showAlert(title: AppStrings.Profile.blockedUserTitle, message: AppStrings.Profile.blockedUserMessage, shouldPopView: true, shouldPopViewToRoot: false, shouldDismissView: false, completion: nil)
        }
        viewModel.onUserInstaSyncError = {
            [weak self] error in
            self?.tryHideLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.handleError(error: error)
            }
        }
        viewModel.onUserInstaSyncSuccess = {
            [weak self] in
            self?.tryHideLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.profileTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }
        viewModel.onUserDetailUpdateError = {
            [weak self] error in
            self?.tryHideLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.handleError(error: error)
            }
        }
        viewModel.onUserDetailUpdateSuccess = {
            [weak self] in
            self?.tryHideLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.loaderCount = 0
                self?.tryHideLoader()
                self?.profileTableView.reloadData()
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
        viewModel.syncUserDataWithServer()
        if viewModel.isViewingSelf {
            checkInstaConnect()
        }
    }
    
    private func checkInstaConnect() {
        self.loaderCount += 1
        self.view.showOrbisLoader()
        viewModel.checkInstagramConnectionStatus()
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
                strongSelf.tryChangeUserProfilePhoto(image: img)
            }
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    private func tryChangeUserProfilePhoto(image: UIImage) {
        guard viewModel.isViewingSelf else { return }
        self.loaderCount += 1
        self.view.showOrbisLoader()
        viewModel.uploadUserPicture(image: image)
    }
    
    func openImagePickerView() {
        setupImagePickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func setupProfilePhotosPickerView() {
        profilePhotosPickerConfig = YPImagePicker.getAppImageViewConfig(allowMultiSelect: true, allowsCrop: false, onStartScreen: .photo)
        profilePhotosPickerController = YPImagePicker(configuration: profilePhotosPickerConfig)
        profilePhotosPickerController.didFinishPicking { [weak self] (items, canceled) in
            guard let strongSelf = self else {
                self?.profilePhotosPickerController.dismiss(animated: true, completion: nil)
                return
            }
            guard !canceled else {
                self?.profilePhotosPickerController.dismiss(animated: true, completion: nil)
                return
            }
            var images = [UIImage]()
            var imagesData = [Data]()
            for item in items {
                switch item {
                case .photo(let photo):
                    let data = photo.image.UIImageToDataJPEG2(compressionRatio: 1)!
                    images.append(photo.image.resizeImage(targetSize: CGSize(width: 800, height: 800)))
                    imagesData.append(data)
                default:
                    break
                }
            }
            strongSelf.viewModel.uploadUserProfilePhotos(imagesData: imagesData) { data, err in
                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.UserProfilePhotoUpload.pendingProfileMediaUploadSuccess), object: nil)
            }
            
            // upload photos
            self?.profilePhotosPickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    func openProfilePhotosPickerView() {
        setupProfilePhotosPickerView()
        self.present(profilePhotosPickerController, animated: true, completion: nil)
    }
    
    func handleViewPhoto(imageView: UIImageView, media: UserProfileMedia) {
        guard let mediaUrl = media.pictureUrl, mediaUrl.count > 0 else { return }
        guard media.mediaType == .image else { return }
        imageFullSizeViewer?.removeFromParent()
        imageFullSizeViewer = nil
        imageFullSizeViewer = (UIStoryboard.getViewController(inStoryboard: "Group", identifier: "orbisImageGalleryVC") as! OrbisImageGalleryViewController)
        imageFullSizeViewer?.storageDirectory = (media.sourceType == .orbis) ? .userProfilePhotos : ProjectStorageDirectories.none
        imageFullSizeViewer?.imagesString = mediaUrl
        imageFullSizeViewer?.preselectedIndex = 0
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
        proPicActionView.hideSecondaryButton = true
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
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.proPicActionView?.actionBtnContainer.alpha = 1
        } completion: { (true) in
        }
    }
    
    private func updateBottomStackComponents(forTab tab: ProfileTab) {
        if viewModel.isViewingSelf {
            switch tab {
            case .photos:
                addPhotosBtnView.isHidden = false
                searchUserBtnView.isHidden = false
                addNewBtnView.isHidden = true
                otherUserMessageBtnView.isHidden = true
                otherUserRightSearchBtnView.isHidden = true
            case .posts:
                addPhotosBtnView.isHidden = true
                searchUserBtnView.isHidden = false
                addNewBtnView.isHidden = false
                otherUserMessageBtnView.isHidden = true
                otherUserRightSearchBtnView.isHidden = true
            case .none:
                addPhotosBtnView.isHidden = false
                searchUserBtnView.isHidden = false
                addNewBtnView.isHidden = true
                otherUserMessageBtnView.isHidden = true
                otherUserRightSearchBtnView.isHidden = true
            }
        }
        else {
            switch tab {
            case .photos:
                addPhotosBtnView.isHidden = true
                searchUserBtnView.isHidden = true
                addNewBtnView.isHidden = true
                otherUserMessageBtnView.isHidden = false
                otherUserRightSearchBtnView.isHidden = false
            case .posts:
                addPhotosBtnView.isHidden = true
                searchUserBtnView.isHidden = true
                addNewBtnView.isHidden = true
                otherUserMessageBtnView.isHidden = false
                otherUserRightSearchBtnView.isHidden = false
            case .none:
                addPhotosBtnView.isHidden = true
                searchUserBtnView.isHidden = true
                addNewBtnView.isHidden = true
                otherUserMessageBtnView.isHidden = false
                otherUserRightSearchBtnView.isHidden = false
            }
        }
        
    }
    
    private func gotoSearchUser() {
        let searchListVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "profileListVC") as! UserSearchListViewController
        self.navigationController?.pushViewController(searchListVC, animated: true)
    }
    
    private func showSettingsView() {
        let settingsMainVC = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "settingsMainVC") as! SettingsMainViewController
        self.navigationController?.pushViewController(settingsMainVC, animated: true)
    }
    
    private func tryOpenCreatePostView() {
        guard viewModel.isViewingSelf else { return }
        openUserCreatePostPage()
    }
    
    private func openUserCreatePostPage() {
        let createPostVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "createPostVC") as! CreatePostViewController
        createPostVC.viewModel = CreatePostViewModel(defaultPublisherGroup: nil, isSelfPublisher: true, allowUserPublisher: true)
        createPostVC.createPostInvoker = CreatePostInvoker.userProfile
        createPostVC.onCreatePostSuccess = {
            [weak self] data in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotificationKeys.PostCreate.postCreateCompleted), object: nil)
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
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    private func showUserListView(type: UsersListType) {
        let listVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "usersListVC") as! UsersListViewController
        listVC.viewModel = UsersListViewModel(user: viewModel.user, type: type)
        self.navigationController?.pushViewController(listVC, animated: true)
    }
    
    private func showUserGroupListView(type: UserGroupListType) {
        let listVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "userGroupListVC") as! UserGroupListViewController
        listVC.viewModel = UserGroupListViewModel(type: type, user: viewModel.user, searchText: "")
        self.navigationController?.pushViewController(listVC, animated: true)
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
    
    private func showOtherProfileMoreActions() {
        let actionSheetVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: AppStrings.Post.Actions.report, style: .default) { [weak self] action in
            self?.showReportProfileView()
        }
        let blockAction = UIAlertAction(title: viewModel.blockUserTitle, style: .default) {
            [weak self] action in
            self?.showBlockUserConfirmation()
        }
        let cancelAction = UIAlertAction(title: AppStrings.cancel, style: .destructive, handler: nil)
        actionSheetVC.addAction(reportAction)
        if viewModel.isUserBlockable {
            actionSheetVC.addAction(blockAction)
        }
        actionSheetVC.addAction(cancelAction)
        self.present(actionSheetVC, animated: true, completion: nil)
    }
    
    private func showBlockUserConfirmation() {
        showConfirmationAlert(title: viewModel.blockUserTitle, message: AppStrings.Profile.blockConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] success in
            if success {
                self?.proceedBlockUser()
            }
        }
    }
    
    private func proceedBlockUser() {
        guard !viewModel.isBlockUnblockProcessing else { return }
        self.showOrbisLoader()
        viewModel.blockUnblock { [weak self] result, error in
            self?.hideOrbisLoader()
            if self?.viewModel.isUserBlocked == true {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showReportProfileView() {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        let reportPopupVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "textEditPopupVC") as! TextEditPopupViewController
        reportPopupVC.modalPresentationStyle = .overFullScreen
        reportPopupVC.shouldAddFullOverlay = true
        reportPopupVC.shouldDismissViewOnTapOutside = false
        reportPopupVC.shouldProceedWithUnchanged = true
        reportPopupVC.contentTitle = AppStrings.Post.Actions.reportProfile
        reportPopupVC.saveBtnTitle = AppStrings.Post.Actions.report
        reportPopupVC.textViewPlaceholder = AppStrings.Post.Actions.reportProfilePlaceholder
        reportPopupVC.contentText = ""
        reportPopupVC.onSave = {
            [weak self] reportText in
            self?.proceedReportProfile(withReportDescription: reportText)
        }
        present(reportPopupVC, animated: true, completion: nil)
    }
    
    private func proceedReportProfile(withReportDescription string: String) {
        self.showOrbisLoader()
        viewModel.reportProfile(withText: string) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.showToastMessage(message: AppStrings.SuccessMessages.profileReported)
            }
            self?.hideOrbisLoader()
        }
    }
}

extension UserProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if viewModel.isViewingSelf {
                let header = tableView.dequeueReusableCell(withIdentifier: "profileHeaderCell") as! ProfileTableHeaderTableViewCell
                
                header.headerActionButtonContainer.isHidden = true
                
                header.dataSource = self
                header.updateViewContent()
                return header
            }
            else {
                let header = tableView.dequeueReusableCell(withIdentifier: "otherUserProfileHeaderCell") as! OtherUserProfileHeaderTableViewCell
                header.headerActionButtonContainer.isHidden = false
                header.dataSource = self
                header.updateViewContent()
                header.onOtherProfileMoreTapped = {
                    [weak self] in
                    self?.showOtherProfileMoreActions()
                }
                return header
            }
        }
        if indexPath.row == 1 {
            if viewModel.isViewingSelf {
                let contentCell = tableView.dequeueReusableCell(withIdentifier: "profileContentCell") as! ProfileContentTableViewCell
                contentCell.parallexScrollDelegate = self
                contentCell.modelDataSource = self
                contentCell.addTabContentView()
                return contentCell
            }
            else {
                if viewModel.isAccountPrivate && !viewModel.isFollowing {
                    let lockedCell = tableView.dequeueReusableCell(withIdentifier: "privateAccountInfoCell") as! PrivateProfileLockTableViewCell
                    return lockedCell
                }
                else {
                    let contentCell = tableView.dequeueReusableCell(withIdentifier: "profileContentCell") as! ProfileContentTableViewCell
                    contentCell.parallexScrollDelegate = self
                    contentCell.modelDataSource = self
                    contentCell.addTabContentView()
                    return contentCell
                }
            }
            
        }
        return UITableViewCell(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        if indexPath.row == 0 {
            if viewModel.isViewingSelf {
                return 135.toCGFloat.relativeToIphone8Width()
            }else {
                return 190.toCGFloat.relativeToIphone8Width()
            }
        }
        if indexPath.row == 1 {
            if !viewModel.isViewingSelf && viewModel.isAccountPrivate && !viewModel.isFollowing {
                return self.view.frame.height - 190.toCGFloat.relativeToIphone8Width() - (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom)
            }
            return tableView.frame.height
        }
        return 0
    }
}

extension UserProfileViewController: OrbisParallexScrollDelegate {
    
    func getCurrentSelectedTabIndex() -> Int {
        return self.currentSelectionIndex
    }
    
    func openFullSizeImage(imageView: UIImageView, data: UserProfileMedia) {
        self.handleViewPhoto(imageView: imageView, media: data)
    }
    
    func getParentViewController() -> UIViewController {
        return self
    }
    
    func showCommonLoader() {
        self.loaderCount += 1
        self.showOrbisLoader()
    }
    
    func hideCommonLoader() {
        self.tryHideLoader()
    }
    
    func profileDidChangeTab(tab: ProfileTab) {
        switch tab {
        case .posts:
            self.currentSelectionIndex = 1
        case .photos:
            self.currentSelectionIndex = 0
        case .none:
            self.currentSelectionIndex = 0
        }
        updateBottomStackComponents(forTab: tab)
    }
    
    func childScrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
    }
    
    func didChangeChildScrollView(scrollView: UIScrollView?) {
        self.childScrollView = scrollView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // determining whether scrollview is scrolling up or down
        
        goingUp = scrollView.panGestureRecognizer.translation(in: scrollView).y < 0
        
        // maximum contentOffset y that parent scrollView can have
        let parentViewMaxContentYOffset = profileTableView.contentSize.height - profileTableView.frame.height
        
        // if scrollView is going upwards
        if goingUp! {
            // if scrollView is a child scrollView
            
            if scrollView == childScrollView {
                // if parent scroll view isn't scrolled maximum (i.e. menu isn't sticked on top yet)
                if profileTableView.contentOffset.y < parentViewMaxContentYOffset && !childScrollingDownDueToParent {
                    
                    // change parent scrollView contentOffset y which is equal to minimum between maximum y offset that parent scrollView can have and sum of parentScrollView's content's y offset and child's y content offset. Because, we don't want parent scrollView go above sticked menu.
                    // Scroll parent scrollview upwards as much as child scrollView is scrolled
                    // Sometimes parent scrollView goes in the middle of screen and stucks there so max is used.
                    let val = max(min(profileTableView.contentOffset.y + (childScrollView?.contentOffset.y ?? 0), parentViewMaxContentYOffset), 0)
                    profileTableView.contentOffset.y = val
                    
                    // change child scrollView's content's y offset to 0 because we are scrolling parent scrollView instead with same content offset change.
                    childScrollView?.contentOffset.y = 0
                }
            }
        }
            // Scrollview is going downwards
        else {
            
            if scrollView == childScrollView {
                // when child view scrolls down. if childScrollView is scrolled to y offset 0 (child scrollView is completely scrolled down) then scroll parent scrollview instead
                // if childScrollView's content's y offset is less than 0 and parent's content's y offset is greater than 0
                if (childScrollView?.contentOffset.y ?? 0) < 0 && profileTableView.contentOffset.y > 0 {
                    
                    // set parent scrollView's content's y offset to be the maximum between 0 and difference of parentScrollView's content's y offset and absolute value of childScrollView's content's y offset
                    // we don't want parent to scroll more that 0 i.e. more downwards so we use max of 0.
                    let val = max(profileTableView.contentOffset.y - abs((childScrollView?.contentOffset.y ?? 0)), 0)
                    profileTableView.contentOffset.y = val
                    // change child scrollView's content's y offset to 0 because we are scrolling parent scrollView instead with same content offset change.
                    childScrollView?.contentOffset.y = 0
                }
            }
            
            // if downward scrolling view is parent scrollView
//            if scrollView == profileTableView {
//                // if child scrollView's content's y offset is greater than 0. i.e. child is scrolled up and content is hiding up
//                // and parent scrollView's content's y offset is less than parentView's maximum y offset
//                // i.e. if child view's content is hiding up and parent scrollView is scrolled down than we need to scroll content of childScrollView first
//                print("Child offset = \(childScrollView?.contentOffset.y ?? 0)")
//                print("Parent offset = \(profileTableView.contentOffset.y)")
//                if (childScrollView?.contentOffset.y ?? 0) > 0 && profileTableView.contentOffset.y < parentViewMaxContentYOffset {
//                    // set if scrolling is due to parent scrolled
//                    childScrollingDownDueToParent = true
//                    // assign the scrolled offset of parent to child not exceding the offset 0 for child scroll view
//                    print("setting max Child offset = \(childScrollView?.contentOffset.y ?? 0)")
//                    print("setting max Parent offset = \(profileTableView.contentOffset.y)")
//                    childScrollView?.contentOffset.y = max((childScrollView?.contentOffset.y ?? 0) - (parentViewMaxContentYOffset - profileTableView.contentOffset.y), 0)
//                    // stick parent view to top coz it's scrolled offset is assigned to child
//                    print("Setting max offset")
//                    profileTableView.contentOffset.y = parentViewMaxContentYOffset
//                    childScrollingDownDueToParent = false
//                }
//            }
        }
    }
}

extension UserProfileViewController: ProfileViewModelDataSource {
    func groupCountTapped() {
        guard viewModel.canInteractWithProfile else { return }
        showUserGroupListView(type: .member)
    }
    
    func followingCountTapped() {
        guard viewModel.canInteractWithProfile else { return }
        showUserListView(type: .followings)
    }
    
    func followerCountTapped() {
        guard viewModel.canInteractWithProfile else { return }
        showUserListView(type: .followers)
    }
    
    func followUnfollowTapped(view: UIView) {
        guard !viewModel.isFollowUnfollowProcessing else { return }
        if viewModel.isAccountPrivate {
            guard !viewModel.isRequestPending else { return }
            tryFollowUnfollow(view: view)
        }
        else {
            tryFollowUnfollow(view: view)
        }
    }
    
    private func tryFollowUnfollow(view: UIView) {
        if viewModel.user.hasFollowed {
            view.showOrbisLoader(withSize: view.frame.height, clearBackground: true, useFullScreen: false)
        }
        else {
            view.showWhiteOrbisLoader(withSize: view.frame.height, clearBackground: true, useFullScreen: false)
        }
        viewModel.followUnfollow { [weak self] data, err in
            DispatchQueue.main.async {
                [weak self] in
                if self?.viewModel.isAccountPrivate == true {
                    self?.loaderCount = 0
                    self?.tryHideLoader()
                    self?.profileTableView.reloadData()
                }
                else {
                    self?.profileTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                }
            }
            view.hideOrbisLoader()
        }
    }
    
    func connectInstagramTapped() {
        guard let instaResponse = viewModel.userInstaResponse, instaResponse.connectedStatus == .notConnected else {
            return
        }
        guard let linkStr = instaResponse.authLink, let url = URL(string: linkStr) else {
            self.showToastMessage(message: AppErrorStrings.invalidLinkProvided)
            return
        }
        let instagramVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "instaConnectVC") as! InstagramConnectViewController
        instagramVC.connectUrl = url
        instagramVC.modalPresentationStyle = .overFullScreen
        instagramVC.onSuccessfullAuthorize = {
            [weak self] in
            NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.userDidConnectInstagram), object: nil)
            self?.syncData()
        }
        present(instagramVC, animated: true, completion: nil)
    }
    
//    private func tryDisconnectInsta() {
//        self.showCommonLoader()
//        self.view.isUserInteractionEnabled = false
//        viewModel.disconnectInstagram { [weak self] data, err in
//            if let error = err {
//                self?.handleError(error: error)
//            }
//            else {
//                DispatchQueue.main.async {
//                    [weak self] in
//                    self?.profileTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
//                }
//            }
//            self?.hideCommonLoader()
//        }
//    }
    
    func getProfileModel() -> ProfileDetailViewModel {
        return viewModel
    }
    
    func selfProPicTapped(view: UIView) {
        let location = view.convert(view.frame.origin, to: self.view)
        let locationY = location.y - self.view.safeAreaInsets.top
        showProPicActionView(inLocation: CGPoint(x: location.x, y: locationY + view.frame.height))
    }
    
    func settingsTapped() {
        guard viewModel.isViewingSelf else { return }
        showSettingsView()
    }
}

extension UserProfileViewController {
    private func createConversationIfNeeded(withUser user: OrbisUser) {
        guard let selfUser = UserSessionManager.shared.currentUser else { return }
        guard selfUser.userKey != user.userKey else { return }
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.getCreatedConversation(of: selfUser, withUser: user) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                if let conversation = data as? OrbisConversation {
                    self?.gotoConversationView(with: conversation)
                }
            }
            self?.hideOrbisLoader()
        }
    }
    
    func gotoConversationView(with object: OrbisConversation) {
        let conversationVC = UIStoryboard.getViewController(inStoryboard: "Chat", identifier: "conversationVC") as! ConversationViewController
        conversationVC.viewModel = ConversationViewModel(conversation: object)
        self.navigationController?.pushViewController(conversationVC, animated: true)
    }
}

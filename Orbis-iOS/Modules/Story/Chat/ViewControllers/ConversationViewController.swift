//
//  ConversationViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import UIKit
import IQKeyboardManager
import GrowingTextView

class ConversationViewController: OrbisLocalizableViewController {

    @IBOutlet weak var participantProPicContainer: RoundedView!
    @IBOutlet weak var participantProPicView: UIImageView!
    @IBOutlet weak var participantNameLabel: UILabel!
    @IBOutlet weak var onlineStatusLabel: UILabel!
    @IBOutlet weak var stackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewContainer: UIView!
    @IBOutlet weak var inputTextView: GrowingTextView!
    
    @IBOutlet weak var chatTableView: UITableView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addAttachmentTapped(_ sender: Any) {
        openMediaPickerView()
    }
    @IBAction func sendTapped(_ sender: Any) {
        guard !inputTextView.text.isEmpty else { return }
        viewModel.sendMessage(text: inputTextView.text) { [weak self] data, err in
            self?.inputTextView.text = ""
            DispatchQueue.main.async { [weak self] in
                self?.chatTableView.scrollToLastItem(animated: false)
                self?.chatTableView.reloadData()
                self?.chatTableView.scrollToLastItem(animated: true)
            }
        }
    }
    
    var viewModel: ConversationViewModel!
    var refreshControl = UIRefreshControl()
    var currentPlayingVideo: ChatVideoCell?
    
    var accessoryOffsetY: CGFloat {
        return 10.toCGFloat.relativeToIphone8Width()
    }
    
    private var isIQKeyboardEnabled: Bool = false
    var isMessagesLoading = false
    
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    
    var imageFullSizeViewer: OrbisImageGalleryViewController?
    
    var chatPhotosVideoPickerConfig: YPImagePickerConfiguration!
    var chatPhotosVideoPickerController: YPImagePicker!
    
    var messageMarkReadTimer = Timer()
    var userActiveStatusRefreshTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        setupTableView()
        handleViewModelActionHandlers()
        updateParticipantInfo()
        syncConversationInfo()
        addParticipantTapActions()
        resetData()
        loadChatData()
        viewModel.markAllMessagesAsRead()
        updateStaticTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isIQKeyboardEnabled = IQKeyboardManager.shared().isEnabled
        IQKeyboardManager.shared().isEnabled = false
        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentPlayingVideo?.player?.pause()
        IQKeyboardManager.shared().isEnabled = self.isIQKeyboardEnabled
        self.view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func updateStaticTexts() {
        inputTextView.placeholder = AppStrings.Messaging.messagePlaceholder
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handlePendingMediaUpload(_:)), name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadFailure), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePendingMediaUpload(_:)), name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadSuccess), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func addParticipantTapActions() {
        let proPicTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleParticipantTap(_:)))
        let nameTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleParticipantTap(_:)))
        participantProPicContainer.isUserInteractionEnabled = true
        participantProPicContainer.addGestureRecognizer(proPicTapGesture)
        participantNameLabel.isUserInteractionEnabled = true
        participantNameLabel.addGestureRecognizer(nameTapGesture)
        
    }
    
    @objc func handleParticipantTap(_ sender: Any) {
        guard let participant = viewModel.participant else { return }
        gotoUserProfileView(withUser: participant)
    }
    
    @objc func handlePendingMediaUpload(_ notification: NSNotification) {
        if notification.name == NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadFailure) {
            if let data = notification.object as? (Error, OrbisChatMessage) {
                viewModel.chatMessages.removeAll(where: {$0.id == data.1.id})
                self.chatTableView.reloadData()
            }
        }
        else {
            if let _ = notification.object as? OrbisChatMessage {
                // do nothing...let firebase observer handle this
            }
        }
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
    
    @objc func handleKeyboardNotification(_ notification: NSNotification) {
        if let userInfo = notification.userInfo, let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let isShowing = notification.name == UIResponder.keyboardWillShowNotification
            stackViewBottomConstraint.constant = isShowing ? keyboardFrame.height : 0
            UIView.animateWithDuration(0, delay: 0) { [weak self] in
                self?.view.layoutIfNeeded()
            } completion: { [weak self] success in
                if isShowing {
                    self?.chatTableView.scrollToLastItem(animated: true)
                }
            }
        }
    }
    
    private func updateParticipantInfo() {
        participantNameLabel.text = viewModel.participantName
        updateProfilePic(viewModel: viewModel)
        updateParticipantLastActiveStatus(text: viewModel.userLastActivityDateString)
        inputViewContainer.isHidden = !viewModel.model.isValidParticipant
    }
    
    private func updateParticipantLastActiveStatus(text: String) {
        onlineStatusLabel.text = text
        userActiveStatusRefreshTimer.invalidate()
        userActiveStatusRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] timer in
            self?.onlineStatusLabel.text = self?.viewModel.userLastActivityDateString
        })
    }
    
    private func updateProfilePic(viewModel: ConversationViewModel) {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.participantPropicLink.isEmpty else {
            participantProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.participantPropicLink
        
        participantProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func setupTableView() {
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        chatTableView.addSubview(refreshControl)
    }
    
    private func syncConversationInfo() {
        viewModel.syncConversationInfo()
    }
    
    @objc func refresh(_ sender: AnyObject) {
        loadPreviousMessages()
    }
    
    func loadPreviousMessages() {
        guard isViewLoaded else {
            self.refreshControl.endRefreshing()
            return
        }
        guard !isMessagesLoading && !viewModel.hasItemsLastPageReached else {
            self.refreshControl.endRefreshing()
            return
        }
        loadMoreChatData()
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onConversationSynched = {
            [weak self] in
            self?.viewModel.markAllMessagesAsRead()
            self?.updateParticipantInfo()
        }
        viewModel.onChatFetched = { [weak self] isInitial in
            self?.hideOrbisLoader()
            self?.isMessagesLoading = false
            if isInitial {
                self?.chatTableView.alpha = 0
                self?.chatTableView.reloadData()
                self?.chatTableView.scrollToLastItem(animated: false)
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
                    self?.chatTableView.alpha = 1
                }
            }
            else {
                self?.chatTableView.reloadData()
            }
            self?.refreshControl.endRefreshing()
        }
        viewModel.onChatFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.isMessagesLoading = false
            self?.refreshControl.endRefreshing()
        }
        viewModel.onChatFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isMessagesLoading = false
            self?.refreshControl.endRefreshing()
        }
        viewModel.onNewMessageObserved = { [weak self] index in
            self?.chatTableView.scrollToLastItem(animated: false)
            self?.chatTableView.beginUpdates()
            self?.chatTableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .top)
            self?.chatTableView.endUpdates()
            self?.chatTableView.scrollToLastItem(animated: true)
            
            self?.messageMarkReadTimer.invalidate()
            self?.messageMarkReadTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                self?.viewModel.markAllMessagesAsRead()
            }
            
        }
        viewModel.onMessageUpdateObserved = { [weak self] index in
            self?.chatTableView.reloadData()
        }
        viewModel.onLastActiveStatusUpdate = { [weak self] text in
            self?.updateParticipantLastActiveStatus(text: text)
        }
    }
    
    private func setupPhotosVideoPickerView() {
        chatPhotosVideoPickerConfig = YPImagePicker.getAppPhotoVideoPickerConfig(allowMultiSelect: false, onStartScreen: .library)
        chatPhotosVideoPickerController = YPImagePicker(configuration: chatPhotosVideoPickerConfig)
        chatPhotosVideoPickerController.didFinishPicking { [weak self] (items, canceled) in
            guard let strongSelf = self else {
                self?.chatPhotosVideoPickerController.dismiss(animated: true, completion: nil)
                return
            }
            guard !canceled else {
                self?.chatPhotosVideoPickerController.dismiss(animated: true, completion: nil)
                return
            }
            for item in items {
                switch item {
                case .photo(let photo):
                    let data = photo.image.UIImageToDataJPEG2(compressionRatio: 1)!
                    strongSelf.viewModel.sendImageMessage(data: data, completion: { data, err in
                        DispatchQueue.main.async { [weak self] in
                            self?.chatTableView.scrollToLastItem(animated: false)
                            self?.chatTableView.reloadData()
                            self?.chatTableView.scrollToLastItem(animated: true)
                        }
                    })
                case .video(let videoMedia):
                    let path = (videoMedia.url.absoluteString)
                    strongSelf.viewModel.sendVideoMessage(videoPath: path) { data, err in
                        DispatchQueue.main.async { [weak self] in
                            self?.chatTableView.scrollToLastItem(animated: false)
                            self?.chatTableView.reloadData()
                            self?.chatTableView.scrollToLastItem(animated: true)
                        }
                    }
                }
            }
            
            self?.chatPhotosVideoPickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    func openMediaPickerView() {
        setupPhotosVideoPickerView()
        self.present(chatPhotosVideoPickerController, animated: true, completion: nil)
    }
    
    // MARK:- Fetch Messages
    
    func resetData() {
        viewModel.initializePagination()
        isMessagesLoading = false
        chatTableView.reloadData()
    }
    
    func loadChatData() {
        isMessagesLoading = true
        self.showOrbisLoader()
        viewModel.fetchMessages()
    }
    
    func loadMoreChatData() {
        isMessagesLoading = true
        self.showOrbisLoader()
        viewModel.fetchMoreMessages()
    }
}

extension ConversationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getMessage(at: indexPath.row)
        if model.isReceived {
            switch model.messageType {
            case .image:
                let receiveCell = tableView.dequeueReusableCell(withIdentifier: "receivedImageMessageCell") as! ChatImageReceivedTVC
                let cellModel = ChatMessageViewModel(message: model, shouldShowDay: false)
                let dayString = cellModel.dateString
                receiveCell.onImageTapped = {
                    [weak self] url in
                    self?.didTapChatImage(linkString: url)
                }
                if indexPath.row == 0 {
                    cellModel.shouldShowDay = true
                }
                else {
                    let prevCellModel = viewModel.getMessage(at: indexPath.row)
                    if (prevCellModel.timestamp?.epochToChatDateString() ?? "") != dayString {
                        cellModel.shouldShowDay = true
                    }
                }
                receiveCell.viewModel = cellModel
                return receiveCell
            case .text:
                let receiveCell = tableView.dequeueReusableCell(withIdentifier: "receivedMessageCell") as! ReceivedMessageTableViewCell
                let cellModel = ChatMessageViewModel(message: model, shouldShowDay: false)
                let dayString = cellModel.dateString
                if indexPath.row == 0 {
                    cellModel.shouldShowDay = true
                }
                else {
                    let prevCellModel = viewModel.getMessage(at: indexPath.row)
                    if (prevCellModel.timestamp?.epochToChatDateString() ?? "") != dayString {
                        cellModel.shouldShowDay = true
                    }
                }
                receiveCell.viewModel = cellModel
                return receiveCell
            case .video:
                let receiveCell = tableView.dequeueReusableCell(withIdentifier: "receivedVideoMessageCell") as! ChatVideoReceivedTVC
                let cellModel = ChatMessageViewModel(message: model, shouldShowDay: false)
                let dayString = cellModel.dateString
                if indexPath.row == 0 {
                    cellModel.shouldShowDay = true
                }
                else {
                    let prevCellModel = viewModel.getMessage(at: indexPath.row)
                    if (prevCellModel.timestamp?.epochToChatDateString() ?? "") != dayString {
                        cellModel.shouldShowDay = true
                    }
                }
                receiveCell.onVideoStartedPlaying = {
                    [weak self] playerCell in
                    if self?.currentPlayingVideo != playerCell {
                        self?.currentPlayingVideo?.player?.pause()
                        self?.currentPlayingVideo = playerCell
                    }
                }
                receiveCell.viewModel = cellModel
                return receiveCell
            }
        }
        else {
            switch model.messageType {
            case .image:
                let sentCell = tableView.dequeueReusableCell(withIdentifier: "sentImageMessageCell") as! ChatImageSentTVC
                let cellModel = ChatMessageViewModel(message: model, shouldShowDay: false)
                let dayString = cellModel.dateString
                sentCell.onImageTapped = {
                    [weak self] url in
                    self?.didTapChatImage(linkString: url)
                }
                if indexPath.row == 0 {
                    cellModel.shouldShowDay = true
                }
                else {
                    let prevCellModel = viewModel.getMessage(at: indexPath.row)
                    if (prevCellModel.timestamp?.epochToChatDateString() ?? "") != dayString {
                        cellModel.shouldShowDay = true
                    }
                }
                sentCell.viewModel = cellModel
                return sentCell
            case .text:
                let sentCell = tableView.dequeueReusableCell(withIdentifier: "sentMessageCell") as! SentMessageTableViewCell
                let cellModel = ChatMessageViewModel(message: model, shouldShowDay: false)
                let dayString = cellModel.dateString
                if indexPath.row == 0 {
                    cellModel.shouldShowDay = true
                }
                else {
                    let prevCellModel = viewModel.getMessage(at: indexPath.row)
                    if (prevCellModel.timestamp?.epochToChatDateString() ?? "") != dayString {
                        cellModel.shouldShowDay = true
                    }
                }
                sentCell.viewModel = cellModel
                return sentCell
            case .video:
                let sentCell = tableView.dequeueReusableCell(withIdentifier: "sentVideoMessageCell") as! ChatVideoSentTVC
                let cellModel = ChatMessageViewModel(message: model, shouldShowDay: false)
                let dayString = cellModel.dateString
                if indexPath.row == 0 {
                    cellModel.shouldShowDay = true
                }
                else {
                    let prevCellModel = viewModel.getMessage(at: indexPath.row)
                    if (prevCellModel.timestamp?.epochToChatDateString() ?? "") != dayString {
                        cellModel.shouldShowDay = true
                    }
                }
                sentCell.onVideoStartedPlaying = {
                    [weak self] playerCell in
                    if self?.currentPlayingVideo != playerCell {
                        self?.currentPlayingVideo?.player?.pause()
                        self?.currentPlayingVideo = playerCell
                    }
                }
                sentCell.viewModel = cellModel
                return sentCell
            }
            
        }
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
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let videoCell = cell as? ChatVideoCell {
            if let player = videoCell.player {
                player.pause()
            }
            if let sentVideoCell = currentPlayingVideo as? ChatVideoSentTVC, let cell = videoCell as? ChatVideoSentTVC, sentVideoCell.viewModel.message.id == cell.viewModel.message.id  {
                self.currentPlayingVideo = nil
            }
            else if let receivedVideoCell = currentPlayingVideo as? ChatVideoReceivedTVC, let cell = videoCell as? ChatVideoReceivedTVC, receivedVideoCell.viewModel.message.id == cell.viewModel.message.id {
                self.currentPlayingVideo = nil
            }
        }
    }
    
    func didTapChatImage(linkString: String) {
        imageFullSizeViewer?.removeFromParent()
        imageFullSizeViewer = nil
        imageFullSizeViewer = (UIStoryboard.getViewController(inStoryboard: "Group", identifier: "orbisImageGalleryVC") as! OrbisImageGalleryViewController)
        imageFullSizeViewer?.storageDirectory = .conversationImages
        imageFullSizeViewer?.imagesString = [linkString]
        imageFullSizeViewer?.preselectedIndex = 0
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

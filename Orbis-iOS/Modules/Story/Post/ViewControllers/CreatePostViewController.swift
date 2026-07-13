//
//  CreatePostViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import UIKit
import KMPlaceholderTextView
import SDWebImage
import AMRAudioSwift
import AVFoundation
import CoreLocation

enum CreatePostInvoker {
    case group
    case profile
    case place
    case feed
    case userProfile
}

class CreatePostViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var wouldPublishAsMessageLabel: UILabel!
    @IBOutlet weak var yourPostLabel: UILabel!
    @IBOutlet weak var postBtn: UIButton!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var publisherContainerView: RoundedView!
    @IBOutlet weak var publisherProPicView: UIImageView!
    @IBOutlet weak var publisherNameLabel: UILabel!
    @IBOutlet weak var dropDownArrowView: UIView!
    @IBOutlet weak var descriptionTextView: KMPlaceholderTextView!
    @IBOutlet weak var audioRecordBtnView: RoundedView!
    
    @IBOutlet weak var photoTypeSectionView: UIView!
    @IBOutlet weak var photoTypeIndicatorImageView: UIImageView!
    @IBOutlet weak var photoTypeIndicatorLabel: UILabel!
    @IBOutlet weak var postImagesCollectionView: UICollectionView!
    @IBOutlet weak var postImagePageControl: UIPageControl!
    
    @IBOutlet weak var checkinTypeSectionView: UIView!
    @IBOutlet weak var checkinTypeIndicatorImageView: UIImageView!
    @IBOutlet weak var checkinTypeIndicatorLabel: UILabel!
    
    @IBOutlet weak var videoTypeSectionView: UIView!
    @IBOutlet weak var videoTypeIndicatorImageView: UIImageView!
    @IBOutlet weak var videoTypeIndicatorLabel: UILabel!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTypeContentView: UIView!
    @IBOutlet weak var audioTypeContentView: UIStackView!
    
    @IBOutlet weak var postLocationStackView: UIStackView!
    @IBOutlet weak var postLocationNameLabel: UILabel!
    @IBOutlet weak var postLocationMarkerIconView: UIImageView!
    @IBOutlet weak var postLocationContentStackView: UIStackView!
    
    @IBOutlet weak var audioRecordingContainer: RoundedView!
    @IBOutlet weak var audioRecordingTrack: OrbisTrackSlider!
    @IBOutlet weak var audioRecordingPlayPauseIV: UIImageView!
    @IBOutlet weak var recordedAudioStackView: UIStackView!
    @IBOutlet weak var audioRecodingDurationLabel: UILabel!
    @IBOutlet weak var audioRecordBtnIcon: UIImageView!
    @IBOutlet weak var audioCloseBtnView: UIView!
    @IBOutlet weak var recordBtn: OrbisLongPressRecordButton!
    @IBOutlet weak var selectedVideoNameLabel: UILabel!
    @IBOutlet weak var recordBtnWidthConstraint: NSLayoutConstraint!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func audioPlayPauseTapped(_ sender: Any) {
        guard let player = self.audioPlayer else { return }
        if isAudioPlaying {
            player.pause()
            audioPlayerTimer.invalidate()
            isAudioPlaying = false
        }
        else {
            player.play()
            audioPlayerTimer.invalidate()
            isAudioPlaying = true
            startAudioPlayTimer()
        }
    }
    
    private func startAudioPlayTimer() {
        audioPlayerTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.audioRecordingTrack.setValue(Float(self.audioPlayer?.currentTime ?? 0), animated: true)
        })
    }
    
    @IBAction func selectPublisherTapped(_ sender: Any) {
        guard !shouldDisableDropDownAction else { return }
        let location = publisherContainerView.convert(publisherContainerView.bounds.origin, to: self.view)
        showDropDownUserList(inLocation: location, tappedViewFrame: publisherContainerView.bounds, leftRightVal: 15.toCGFloat.relativeToIphone8Width())
    }
    @IBAction func createTapped(_ sender: Any) {
        tryCreatePost()
    }
    @IBAction func audioTypeBtnTapped(_ sender: Any) {
        guard viewModel.type != .audioPost else { return }
        viewModel.type = .audioPost
        updatePostTypeUI()
    }
    @IBAction func photoTypeBtnTapped(_ sender: Any) {
        openImagePickerView()
    }
    @IBAction func checkinTypeBtnTapped(_ sender: Any) {
        if viewModel.postPlace != nil {
            guard isUserNearSelectedPlace else {
                if viewModel.type == .checkinPost {
                    viewModel.isCheckinPost = false
                    viewModel.type = .textPost
                }
                else {
                    viewModel.isCheckinPost = false
                }
                self.updatePostTypeUI(clearContent: false)
                return
            }
            if viewModel.type == .checkinPost {
                viewModel.isCheckinPost = false
                viewModel.type = .textPost
                //viewModel.isCheckinPost = true
                //viewModel.type = .checkinPost
            }
            else {
                viewModel.isCheckinPost = !viewModel.isCheckinPost
                if viewModel.isCheckinPost == true {
                    viewModel.type = .checkinPost
                }
            }
            self.updatePostTypeUI(clearContent: false)
            return
        }
        guard !shouldDisablePlaceSelection else {
            self.viewModel.type = .checkinPost
            self.updatePostTypeUI(clearContent: false)
            return
        }
        showSearchCheckinView()
    }
    @IBAction func videoTypeBtnTapped(_ sender: Any) {
        openVideoPickerView()
    }
    @IBAction func audioTypeViewCloseTapped(_ sender: Any) {
        audioPlayer?.pause()
        audioPlayerTimer.invalidate()
        isAudioPlaying = false
        viewModel.type = .textPost
        updatePostTypeUI()
    }
    @IBAction func imageTypeViewCloseTapped(_ sender: Any) {
        viewModel.type = .textPost
        updatePostTypeUI()
    }
    
    @IBAction func pageControlValueChanged(_ sender: Any) {
        guard postImagePageControl != nil else { return }
        guard isImagePostPageControlTap else { return }
        isImagePostPageControlTap = false
        let currentPage = postImagePageControl.currentPage
        let pageWidth = self.postImagesCollectionView.frame.size.width
        let scrollTo = CGPoint(x: pageWidth * currentPage.toCGFloat, y: 0)
        postImagesCollectionView.setContentOffset(scrollTo, animated: true)
    }
    
    lazy var displayLink : CADisplayLink? = {
        var instance = CADisplayLink(target: self, selector: #selector(self.performRecordTick(_:)))
        instance.isPaused = true
        instance.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        return instance
    }()
    
    var isImagePostPageControlTap = true
    
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
        if self.dropDownListView != nil {
            return false
        }
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if mainScrollView.frame.contains(panGesturePoint) {
            return mainScrollView.contentOffset.y <= 0
        }
        return true
    }
    
    var viewModel: CreatePostViewModel!
    var shouldDisableDropDownAction: Bool = false
    var shouldDisablePlaceSelection: Bool = false
    var createPostInvoker: CreatePostInvoker!
    var restrictPage = false
    var isUserNearSelectedPlace: Bool {
        
//        guard let userLocation = UserSessionManager.shared.userCurrentLocation, let placeLoc = viewModel.postPlace?.coordinates else { return false }
        //MARK: update location to map location
        guard let userLocation = Constants.location?.coordinate, let placeLoc = viewModel.postPlace?.coordinates else { return false }
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let coordinates = CLLocation(latitude: placeLoc.latitude ?? 0, longitude: placeLoc.longitude ?? 0)
        return (userLoc.distance(from: coordinates) / 1000) <= 1
    }
    
    weak var dropDownListView: DropDownSearchListView?
    var onCreatePostSuccess: ((Any?) -> Void)?
    
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    var defaultPostType: OrbisPostType = .textPost
    
    //    fileprivate var audioRecordingTimer = Timer()
    let duration : Double = AppValues.maxAudioRecordTime
    var progress : Double = 0.0
    var startTime : CFTimeInterval?
    fileprivate var audioRecorder = AMRAudioRecorder.shared
    fileprivate var state: OrbisVoiceRecorderState = .normal {
        didSet {
            let record_ic = #imageLiteral(resourceName: "post-voice-type-ic")
            switch state {
            case .normal:
                audioRecordBtnIcon.image = record_ic
                audioRecordingContainer.backgroundColor = UIColor(named: AppColors.appBlack.rawValue)
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 10, initialSpringVelocity: 20, options: [.curveEaseIn]) {
                    [weak self] in
                    guard let self = self else { return }
                    self.audioRecordingContainer.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.audioRecordingContainer.layoutIfNeeded()
                } completion: { success in
                }
                
            case .recording:
                audioRecordBtnIcon.image = record_ic
                audioRecordingContainer.backgroundColor = UIColor(named: AppColors.appBlack.rawValue)
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 10, initialSpringVelocity: 20, options: [.curveEaseIn]) {
                    [weak self] in
                    guard let self = self else { return }
                    self.audioRecordingContainer.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
                    self.audioRecordingContainer.layoutIfNeeded()
                } completion: { success in
                }
                
            }
        }
    }
    private var audioPlayer: AVAudioPlayer?
    private var audioPlayerTimer = Timer()
    private var isAudioPlaying: Bool = false {
        didSet {
            updatePlayPauseIcon()
        }
    }
    var playPauseIcon: UIImage? {
        return (isAudioPlaying == true) ? UIImage(named: "voice-pause-btn") : UIImage(named: "voice-play-btn")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePublisherInView()
        viewModel.type = defaultPostType
        viewModel.isCheckinPost = isUserNearSelectedPlace
        updatePostTypeUI()
        setupPostImagesCollectionView()
        setupInputViews()
        updateStaticTexts()
        if !shouldDisableDropDownAction {
            loadRecommendedGroups()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetAudioRecorder()
    }
    
    override func updateStaticTexts() {
        wouldPublishAsMessageLabel.text = AppStrings.Post.publishAsIndicator
        yourPostLabel.text = AppStrings.Post.yourPost
        descriptionTextView.placeholder = AppStrings.Post.postDescriptionPlaceholder
        photoTypeIndicatorLabel.text = AppStrings.Post.photoType
        checkinTypeIndicatorLabel.text = AppStrings.Post.checkinType
        videoTypeIndicatorLabel.text = AppStrings.Post.videoType
        postBtn.setTitle(AppStrings.Post.post, for: .normal)
    }
    
    private func loadRecommendedGroups() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.loadRecommendedGroups { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            self?.hideOrbisLoader()
        }
    }
    
    func updatePlayPauseIcon() {
        audioRecordingPlayPauseIV.image = playPauseIcon
    }
    
    private func resetAudioRecorder() {
        audioRecorder.stopRecord()
        audioRecorder.delegate = nil
    }
    
    func setupInputViews() {
        descriptionTextView.delegate = self
        
        recordBtn.delegate = self
        setupDisplayLink()
        
        dropDownArrowView.isHidden = shouldDisableDropDownAction
        
        postLocationContentStackView.isUserInteractionEnabled = true
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostLocationStack(_:)))
        postLocationContentStackView.addGestureRecognizer(locationTapGesture)
    }
    
    @objc private func didTapPostLocationStack(_ gesture: UITapGestureRecognizer) {
        guard !shouldDisablePlaceSelection else { return }
        viewModel.postPlace = nil
        if viewModel.type == .checkinPost {
            viewModel.type = .textPost
        }
        viewModel.isCheckinPost = false
        updatePostTypeUI(clearContent: false)
    }
    
    func setupPostImagesCollectionView() {
        postImagesCollectionView.delegate = self
        postImagesCollectionView.dataSource = self
    }
    
    private func updateVideoSelectionLabel() {
        var videoSelectedString = ""
        for videoString in viewModel.postVideo ?? [] {
            videoSelectedString += String(videoString.split(separator: "/").last ?? "")
            if videoString != (viewModel.postVideo ?? []).last {
                videoSelectedString += "\n"
            }
        }
        selectedVideoNameLabel.text = videoSelectedString
    }
    
    private func setupImagePickerView() {
        config = YPImagePicker.getAppImageViewConfig(allowMultiSelect: true, allowsCrop: false, onStartScreen: .photo)
        imagePickerController = YPImagePicker(configuration: config)
        imagePickerController.didFinishPicking { [weak self] (items, canceled) in
            guard let strongSelf = self else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            guard !canceled else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
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
            strongSelf.viewModel.type = .imagePost
            strongSelf.updatePostTypeUI()
            strongSelf.viewModel.postImages = images
            strongSelf.viewModel.postImagesData = imagesData
            strongSelf.postImagesCollectionView.reloadData()
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setupVideoPickerView() {
        config = YPImagePicker.getAppVideoPickerConfig(allowMultiSelect: false, onStartScreen: .video)
        imagePickerController = YPImagePicker(configuration: config)
        imagePickerController.didFinishPicking { [weak self] (items, canceled) in
            guard let strongSelf = self else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            guard !canceled else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            var videos = [String]()
            for item in items {
                switch item {
                case .video(v: let videoMedia):
                    videos.append(videoMedia.url.absoluteString)
                default:
                    break
                }
            }
            strongSelf.viewModel.type = .videoPost
            strongSelf.updatePostTypeUI()
            strongSelf.viewModel.postVideo = videos
            strongSelf.updateVideoSelectionLabel()
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    func openImagePickerView() {
        setupImagePickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func openVideoPickerView() {
        setupVideoPickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func updatePublisherInView() {
        publisherNameLabel.text = viewModel.publisherName
        publisherContainerView.borderWidth = viewModel.publisherBorderWidth
        publisherContainerView.borderColor = viewModel.groupBaseColor
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.publisherProPicLink.isEmpty else {
            publisherProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.publisherProPicLink
        
        publisherProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: (viewModel.publisher == nil) ? .groupPictures : .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func updateUserSelection(user: OrbisUser) {
        viewModel.groupPublisher = nil
        viewModel.publisher = user
        updatePublisherInView()
    }
    
    private func updateGroupSelection(group: Group) {
        viewModel.publisher = nil
        viewModel.groupPublisher = group
        updatePublisherInView()
    }
    
    private func removeDropDownSelectionView() {
        dropDownListView?.removeFromSuperview()
        dropDownListView = nil
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.dropDownArrowView.transform = CGAffineTransform(rotationAngle: 0.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    private func showDropDownUserList(inLocation point: CGPoint, tappedViewFrame: CGRect, leftRightVal: CGFloat) {
        removeDropDownSelectionView()
        let userSelectDropDownList = DropDownSearchListView(frame: self.view.bounds)
        userSelectDropDownList.viewModel = DropdownSearchListViewModel(users: viewModel.dropDownUserList, groups: viewModel.recommendedGroups)
        userSelectDropDownList.actionBtnContainer.alpha = 0
        self.view.addSubview(userSelectDropDownList)
        userSelectDropDownList.translatesAutoresizingMaskIntoConstraints = false
        userSelectDropDownList.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        userSelectDropDownList.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        userSelectDropDownList.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        userSelectDropDownList.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.view.bringSubviewToFront(userSelectDropDownList)
        let originY = point.y + tappedViewFrame.height - 5.toCGFloat
        userSelectDropDownList.btnTopConstraint.constant = originY
        userSelectDropDownList.btnLeadingConstraint.constant = leftRightVal
        userSelectDropDownList.btnTrailingConstraint.constant = leftRightVal
        userSelectDropDownList.actionBtnContainer.autoresizesSubviews = true
        userSelectDropDownList.actionBtnContainer.layoutIfNeeded()
        userSelectDropDownList.contentView.layoutIfNeeded()
        userSelectDropDownList.actionBtnContainer.isHidden = false
        self.dropDownListView = userSelectDropDownList
        self.dropDownListView?.onOutsideViewTapped = {
            [weak self] in
            self?.removeDropDownSelectionView()
        }
        self.dropDownListView?.onUserSelected = {
            [weak self] (user) in
            self?.removeDropDownSelectionView()
            self?.updateUserSelection(user: user)
        }
        self.dropDownListView?.onGroupSelected = {
            [weak self] (group) in
            self?.removeDropDownSelectionView()
            self?.updateGroupSelection(group: group)
        }
        self.dropDownListView?.onSearchReturnTap = {
            [weak self] text in
            self?.showSearchGroupView(withText: text)
        }
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.dropDownListView?.actionBtnContainer.alpha = 1
            self?.dropDownArrowView.transform = CGAffineTransform(rotationAngle: 180.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    func updatePostTypeUI(clearContent: Bool = true) {
        updateTextViewHeight()
        updateImageTypeContentVisibility()
        updateAudioTypeContentVisibility()
        updateVideoTypeContentVisibility()
        updatePostCheckinVisibilityAndContent()
        if clearContent {
            clearImages()
            clearRecording()
            clearVideos()
        }
        switch viewModel.type {
        case .audioPost:
            if viewModel.isCheckinPost {
                updateTypeSectionViews(selectedLabels: [checkinTypeIndicatorLabel], selectedIcons: [checkinTypeIndicatorImageView], unselectedLabels: [photoTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [photoTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
            else {
                updateTypeSectionViews(selectedLabels: nil, selectedIcons: nil, unselectedLabels: [checkinTypeIndicatorLabel, photoTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [checkinTypeIndicatorImageView, photoTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
        case .checkinPost:
            viewModel.isCheckinPost = true
            updateTypeSectionViews(selectedLabels: [checkinTypeIndicatorLabel], selectedIcons: [checkinTypeIndicatorImageView], unselectedLabels: [photoTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [photoTypeIndicatorImageView, videoTypeIndicatorImageView])
        case .eventPost:
            if viewModel.isCheckinPost {
                updateTypeSectionViews(selectedLabels: [checkinTypeIndicatorLabel], selectedIcons: [checkinTypeIndicatorImageView], unselectedLabels: [photoTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [photoTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
            else {
                updateTypeSectionViews(selectedLabels: nil, selectedIcons: nil, unselectedLabels: [checkinTypeIndicatorLabel, photoTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [checkinTypeIndicatorImageView, photoTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
        case .imagePost:
            if viewModel.isCheckinPost {
                updateTypeSectionViews(selectedLabels: [photoTypeIndicatorLabel, checkinTypeIndicatorLabel], selectedIcons: [photoTypeIndicatorImageView, checkinTypeIndicatorImageView], unselectedLabels: [videoTypeIndicatorLabel], unselectedIcons: [videoTypeIndicatorImageView])
            }
            else {
                updateTypeSectionViews(selectedLabels: [photoTypeIndicatorLabel], selectedIcons: [photoTypeIndicatorImageView], unselectedLabels: [checkinTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [checkinTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
        case .textPost:
            if viewModel.isCheckinPost {
                updateTypeSectionViews(selectedLabels: [checkinTypeIndicatorLabel], selectedIcons: [checkinTypeIndicatorImageView], unselectedLabels: [photoTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [photoTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
            else {
                updateTypeSectionViews(selectedLabels: nil, selectedIcons: nil, unselectedLabels: [checkinTypeIndicatorLabel, photoTypeIndicatorLabel, videoTypeIndicatorLabel], unselectedIcons: [checkinTypeIndicatorImageView, photoTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
        case .videoPost:
            if viewModel.isCheckinPost {
                updateTypeSectionViews(selectedLabels: [videoTypeIndicatorLabel, checkinTypeIndicatorLabel], selectedIcons: [videoTypeIndicatorImageView, checkinTypeIndicatorImageView], unselectedLabels: [photoTypeIndicatorLabel], unselectedIcons: [videoTypeIndicatorImageView])
            }
            else {
                updateTypeSectionViews(selectedLabels: [videoTypeIndicatorLabel], selectedIcons: [videoTypeIndicatorImageView], unselectedLabels: [checkinTypeIndicatorLabel, photoTypeIndicatorLabel], unselectedIcons: [checkinTypeIndicatorImageView, videoTypeIndicatorImageView])
            }
        case .unknown:
            return
        }
    }
    
    private func updateTextViewHeight() {
        switch viewModel.type {
        case .checkinPost, .textPost, .videoPost:
            textViewHeightConstraint.constant = 200.toCGFloat.relativeToIphone8Width()
            break
        default:
            textViewHeightConstraint.constant = 60.toCGFloat.relativeToIphone8Width()
            break
        }
    }
    
    private func updatePostCheckinVisibilityAndContent() {
        postLocationStackView.isHidden = viewModel.postPlace == nil
        postLocationNameLabel.text = viewModel.postPlaceName
    }
    
    private func updateImageTypeContentVisibility() {
        switch viewModel.type {
        case .imagePost:
            imageTypeContentView.isHidden = false
            postImagesCollectionView.reloadData()
            break
        default:
            imageTypeContentView.isHidden = true
            break
        }
    }
    
    private func updateVideoTypeContentVisibility() {
        switch viewModel.type {
        case .videoPost:
            selectedVideoNameLabel.isHidden = false
            updateVideoSelectionLabel()
            break
        default:
            selectedVideoNameLabel.isHidden = true
            break
        }
    }
    
    private func clearImages() {
        viewModel.postImages = []
        viewModel.postImagesData = []
    }
    
    private func clearRecording() {
        viewModel.postAudio = nil
        stopRecording()
    }
    
    private func clearVideos() {
        viewModel.postVideo = nil
    }
    
    private func startStopRecording() {
        switch state {
        case .normal:
            startRecording()
        case .recording:
            stopRecording()
        }
    }
    
    private func startRecording() {
        audioRecorder.delegate = self
        self.showToastMessage(message: AppStrings.Post.recording)
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.audioRecorder.stopPlay()
                self.audioRecorder.startRecord()
            }
        }
    }
    
    @objc private func performRecordTick(_ displayLink: CADisplayLink) {
        if (progress > duration) {
            stopRecording()
            setupDisplayLink()
            return
        }
        if let startTime = startTime {
            let elapsedTime = CACurrentMediaTime() - startTime
            self.progress += elapsedTime
            self.startTime = CACurrentMediaTime()
        }
        guard let url = audioRecorder.recorder?.url else { return }
        do {
            let audioData = try Data(contentsOf: url)
            let player = try AVAudioPlayer(data: audioData)
            self.audioRecodingDurationLabel.text = player.duration.toDurationString()
        }
        catch {
            debugPrint("Error in recording audio")
        }
    }
    
    private func stopRecording() {
        guard audioRecorder.isRecording else { return }
        self.showToastMessage(message: AppStrings.Post.recordingStopped)
        resetAudioRecorder()
    }
    
    private func updateRecordFinishContent() {
        updateRecordedAudioVisibility()
        if let audio = viewModel.postAudio {
            do {
                audioPlayer = try AVAudioPlayer(data: audio.data)
                audioPlayer?.delegate = self
                self.audioRecordingTrack.minimumValue = 0
                self.audioRecordingTrack.maximumValue = Float(audioPlayer?.duration ?? 0)
                self.audioRecordingTrack.setValue(Float(audioPlayer?.currentTime ?? 0), animated: false)
                self.isAudioPlaying = false
            }
            catch {
                self.showToastMessage(message: AppErrorStrings.cannotPlayAudio)
            }
        }
    }
    
    private func playPauseRecording() {
        audioRecorder.stopPlay()
    }
    
    private func updateRecordedAudioVisibility() {
        guard viewModel.type == .audioPost else {
            recordedAudioStackView.isHidden = true
            audioTypeContentView.isHidden = true
            audioRecordBtnView.isHidden = false
            return
        }
        if let _ = viewModel.postAudio {
            recordedAudioStackView.isHidden = false
            audioTypeContentView.isHidden = true
        }
        else {
            recordedAudioStackView.isHidden = true
            audioTypeContentView.isHidden = false
        }
    }
    
    private func updateAudioTypeContentVisibility() {
        switch viewModel.type {
        case .audioPost:
            audioTypeContentView.isHidden = false
            audioRecordBtnView.isHidden = true
            recordedAudioStackView.isHidden = true
            state = .normal
            requestMicrophonePermissionIfNeeded()
            self.audioRecodingDurationLabel.text = Double(0).toDurationString()
            updateRecordedAudioVisibility()
            break
        default:
            state = .normal
            audioTypeContentView.isHidden = true
            recordedAudioStackView.isHidden = true
            audioRecordBtnView.isHidden = viewModel.type == .imagePost
            break
        }
    }
    
    private func requestMicrophonePermissionIfNeeded() {
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("granted")
                    
                    do {
                        try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                        try session.setActive(true)
                    }
                    catch {
                        print("Couldn't set Audio session category")
                    }
                } else{
                    print("not granted")
                }
            })
        }
    }
    
    private func updateTypeSectionViews(selectedLabels: [UILabel]?, selectedIcons: [UIImageView]?, unselectedLabels: [UILabel], unselectedIcons: [UIImageView]) {
        if let selectedLabels = selectedLabels {
            for label in selectedLabels {
                label.textColor = UIColor(named: AppColors.appBlack.rawValue)
            }
        }
        if let selectedIcons = selectedIcons {
            for icon in selectedIcons {
                icon.tintColor = UIColor(named: AppColors.appBlack.rawValue)
            }
        }
        
        for label in unselectedLabels {
            label.textColor = UIColor(named: AppColors.appWarmGray2.rawValue)
        }
        for icon in unselectedIcons {
            icon.tintColor = UIColor(named: AppColors.appWarmGray2.rawValue)
        }
    }
    
    private func showSearchGroupView(withText text: String) {
        let searchGroupVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "searchGroupVC") as! SearchGroupViewController
        searchGroupVC.viewModel = GroupListViewModel(searchText: text)
        searchGroupVC.modalPresentationStyle = .overFullScreen
        searchGroupVC.onGroupSelect = { [weak self]
            group in
            self?.updateGroupSelection(group: group)
        }
        presentPanModal(searchGroupVC)
    }
    
    private func showSearchCheckinView() {
        let searchCheckinVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "searchCheckinVC") as! SearchCheckinViewController
        searchCheckinVC.modalPresentationStyle = .overFullScreen
        searchCheckinVC.onCheckinSelect = { [weak self]
            place in
            guard let self = self else { return }
            self.viewModel.postPlace = place
            if self.viewModel.type == .textPost {
                if self.isUserNearSelectedPlace {
                    self.viewModel.type = .checkinPost
                }
            }
            else {
                self.viewModel.isCheckinPost = self.isUserNearSelectedPlace
            }
            self.updatePostTypeUI(clearContent: false)
            self.updatePublisherInView()
        }
        presentPanModal(searchCheckinVC)
    }
    
    private func tryCreatePost() {
        if viewModel.type == .textPost || viewModel.type == .imagePost || viewModel.type == .audioPost || viewModel.type == .videoPost || viewModel.type == .checkinPost {
            self.showOrbisLoader()
            viewModel.tryCreatePost { [weak self] data, err in
                guard let self = self else { return }
                if let error = err {
                    self.handleError(error: error)
                    self.hideOrbisLoader()
                }
                else {
                    if self.viewModel.isCheckinPost, var post = data as? OrbisFeedPost, let dominantGroupKey = post.place?.dominantGroupKey, dominantGroupKey != post.group?.groupKey {
                        self.viewModel.fetchGroupDetails(withKey: dominantGroupKey) { [weak self] result, error in
                            guard let self = self else { return }
                            post.place?.dominantGroup = result as? Group
                            self.dismiss(animated: true) {
                                [weak self] in
                                guard let self = self else { return }
                                if !self.viewModel.isCheckinPost, let place = self.viewModel.postPlace, let _ = place.placeKey {
                                    self.onCreatePostSuccess?(place)
                                }
                                else {
                                    self.onCreatePostSuccess?(post)
                                }
                            }
                            self.hideOrbisLoader()
                        }
                    }
                    else {
                        self.dismiss(animated: true) {
                            [weak self] in
                            guard let self = self else { return }
                            if !self.viewModel.isCheckinPost, let place = self.viewModel.postPlace, let _ = place.placeKey {
                                self.onCreatePostSuccess?(place)
                            }
                            else {
                                Constants.lastCheckinPlace = (data as? OrbisFeedPost)?.place?.toPlaceDetails()
                                Constants.lastCheckInPolygonCoordinateKey = (data as? OrbisFeedPost)?.checkInPolygonCoordinateKey
                                Constants.isSelfCheckIn = self.restrictPage
                                self.onCreatePostSuccess?(data as? OrbisFeedPost)
                            }
                        }
                        self.hideOrbisLoader()
                    }
                }
            }
        }
        else {
            self.showToastMessage(message: AppErrorStrings.invalidPostType)
        }
    }
}

extension CreatePostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        let count = viewModel.postImagesCount
        postImagePageControl.numberOfPages = count
        postImagePageControl.currentPage = 0
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageItemCell", for: indexPath) as! ImagePostItemCollectionViewCell
        cell.image = viewModel.postImages[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension CreatePostViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == postImagesCollectionView else { return }
        guard isImagePostPageControlTap else { return }
        let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / witdh
        let roundedIndex = round(index)
        self.postImagePageControl.currentPage = Int(roundedIndex)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == postImagesCollectionView else { return }
        postImagePageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isImagePostPageControlTap = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == postImagesCollectionView else { return }
        postImagePageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isImagePostPageControlTap = true
    }
}

extension CreatePostViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        viewModel.postDescription = textView.text
    }
}

extension CreatePostViewController: AMRAudioRecorderDelegate {
    func audioRecorderDidStartRecording(_ audioRecorder: AMRAudioRecorder) {
        print("*********************start recording*********************")
        DispatchQueue.main.async {
            [weak self] in
            self?.state = .recording
        }
    }
    
    func audioRecorderDidCancelRecording(_ audioRecorder: AMRAudioRecorder) {
        print("*********************cancel recording*********************")
        DispatchQueue.main.async {
            [weak self] in
            self?.state = .normal
            self?.stopRecording()
        }
        
    }
    
    func audioRecorderDidStopRecording(_ audioRecorder: AMRAudioRecorder, withURL url: URL?) {
        print("*********************stop recording*********************")
        DispatchQueue.main.async {
            [weak self] in
            self?.state = .normal
            self?.stopRecording()
        }
        guard let url = url, let data = try? Data(contentsOf: url) else {
            return
        }
        let amrData = AMRAudio.encodeWAVEDataToAMRData(waveData: data, channels: 1, bitsPerSample: 16)
        let wavData = AMRAudio.decodeAMRDataToWAVEData(amrData: amrData)
        let voice = OrbisVoice(duration: AMRAudioRecorder.audioDuration(from: data), data: wavData, title: UUID().uuidString)
        viewModel.postAudio = voice
        updateRecordFinishContent()
    }
    
    func audioRecorderDidFinishRecording(_ audioRecorder: AMRAudioRecorder, successfully flag: Bool) {
        let result = flag ? "successfully" : "unsuccessfully"
        print("*********************finish recording \(result)*********************")
    }
}

extension CreatePostViewController: OrbisLongPressRecordButtonDelegate {
    // MARK: LongPressRecordButton Delegate
    
    func longPressRecordButtonDidStartLongPress(_ button: OrbisLongPressRecordButton) {
        startTime = CACurrentMediaTime()
        displayLink?.isPaused = false
        if state == .recording {
            stopRecording()
            return
        }
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1113)) {
            DispatchQueue.main.async {
                [weak self] in
                self?.startRecording()
            }
        }
    }
    
    func longPressRecordButtonDidStopLongPress(_ button: OrbisLongPressRecordButton) {
        setupDisplayLink()
        stopRecording()
    }
    
    // MARK: DisplayLink
    fileprivate func setupDisplayLink() {
        progress = 0.0
        startTime = CACurrentMediaTime()
        displayLink?.isPaused = true
    }
}

extension CreatePostViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isAudioPlaying = false
        audioPlayerTimer.invalidate()
        audioRecordingTrack.setValue(Float(player.currentTime), animated: true)
    }
}

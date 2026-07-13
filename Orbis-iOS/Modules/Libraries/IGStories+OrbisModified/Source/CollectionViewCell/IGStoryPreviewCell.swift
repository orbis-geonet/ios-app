//
//  OrbisStoryPreviewCell.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 06/09/17.
//  Copyright © 2017 DrawRect. All rights reserved.
//

import UIKit
import AVKit

protocol StoryPreviewProtocol: AnyObject {
    func didCompletePreview()
    func moveToPreviousStory()
    func didTapCloseButton()
    func didFinishPlayingStory() -> Bool
    func didSeenStory(postKey: String)
    func pushViewController(viewController: UIViewController)
    func panPresentViewController(viewController: UIViewController)
}
enum SnapMovementDirectionState {
    case forward
    case backward
}
//Identifiers
fileprivate let snapViewTagIndicator: Int = 8

final class OrbisStoryPreviewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    //MARK: - Delegate
    public weak var delegate: StoryPreviewProtocol? {
        didSet { storyHeaderView.delegate = self }
    }
    
    //MARK:- Private iVars
    private lazy var storyHeaderView: OrbisStoryPreviewHeaderView = {
        let v = OrbisStoryPreviewHeaderView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        return v
    }()
    private lazy var storyFooterView: StoryFooterView = {
        let v = StoryFooterView()
        v.onReadMoreTapped = {
            [weak self] in
            self?.showLargeTextView()
        }
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        return v
    }()
    private lazy var longPress_gesture: UILongPressGestureRecognizer = {
        let lp = UILongPressGestureRecognizer.init(target: self, action: #selector(didLongPress(_:)))
        lp.minimumPressDuration = 0.2
        lp.delegate = self
        return lp
    }()
    private lazy var tap_gesture: UITapGestureRecognizer = {
        let tg = UITapGestureRecognizer(target: self, action: #selector(didTapSnap(_:)))
        tg.cancelsTouchesInView = true
        tg.numberOfTapsRequired = 1
        tg.delegate = self
        return tg
    }()
    private var storyLargeTextViewer: StoryLargeTextViewer?
    private var storyLargeTVBottomConstraint: NSLayoutConstraint?
    var hasStoryBeenStopped = false
    
    private var previousSnapIndex: Int {
        return snapIndex - 1
    }
    private var snapViewXPos: CGFloat {
        return (snapIndex == 0) ? 0 : scrollview.subviews[previousSnapIndex].frame.maxX
    }
    private var videoSnapIndex: Int = 0
    private var handpickedSnapIndex: Int = 0
    var retryBtn: IGRetryLoaderButton!
    var longPressGestureState: UILongPressGestureRecognizer.State?
    var isLongPressGestureActive = false
    
    //MARK:- Public iVars
    public var direction: SnapMovementDirectionState = .forward
    public let scrollview: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.isScrollEnabled = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    public var getSnapIndex: Int {
        return snapIndex
    }
    public var snapIndex: Int = 0 {
        didSet {
            guard !self.hasStoryBeenStopped else {
                var newIndex = snapIndex - 1
                let count = story?.posts.count ?? 0
                if count <= 0 {
                    snapIndex = 0
                    handpickedSnapIndex = 0
                    return
                }
                if newIndex < 0 {
                    newIndex = 0
                }
                if newIndex > count - 1 {
                    newIndex = count - 1
                }
                snapIndex = newIndex
                handpickedSnapIndex = newIndex
                return
            }
            scrollview.isUserInteractionEnabled = true
            switch direction {
                case .forward:
                    if snapIndex < story?.snapsCount ?? 0 {
                        if let snap = story?.posts[snapIndex] {
                            if snap.postType != .videoPost {
                                if let snapView = getSnapview() {
                                    startRequest(snapView: snapView, with: snap.mediaUrls?.first ?? "", snap: snap)
                                } else {
                                    let snapView = createSnapView(mimeType: snap.postType)
                                    startRequest(snapView: snapView, with: snap.mediaUrls?.first ?? "", snap: snap)
                                }
                            }else {
                                if let videoView = getVideoView(with: snapIndex) {
                                    startPlayer(videoView: videoView, with: snap.signedUrls?.first ?? "", snap: snap)
                                }else {
                                    let videoView = createVideoView()
                                    startPlayer(videoView: videoView, with: snap.signedUrls?.first ?? "", snap: snap)
                                }
                            }
                            fillHeaderView(withSnap: snap)
                            
                            // fill footer
                            fillFooterView(withSnap: snap)

                        }
                }
                case .backward:
                    if snapIndex < story?.snapsCount ?? 0 {
                        if let snap = story?.posts[snapIndex] {
                            if snap.postType != .videoPost {
                                if let snapView = getSnapview() {
                                    self.startRequest(snapView: snapView, with: snap.mediaUrls?.first ?? "", snap: snap)
                                }
                                else {
                                    let snapView = createSnapView(mimeType: snap.postType)
                                    startRequest(snapView: snapView, with: snap.mediaUrls?.first ?? "", snap: snap)
                                }
                            }else {
                                if let videoView = getVideoView(with: snapIndex) {
                                    startPlayer(videoView: videoView, with: snap.signedUrls?.first ?? "", snap: snap)
                                }
                                else {
                                    let videoView = self.createVideoView()
                                    self.startPlayer(videoView: videoView, with: snap.signedUrls?.first ?? "", snap: snap)
                                }
                            }
                            fillHeaderView(withSnap: snap)
                            
                            // fill footer
                            fillFooterView(withSnap: snap)
                        }
                }
            }
        }
    }
    public var story: OrbisStory? {
        didSet {
            storyHeaderView.story = story
            if let borderColor = story?.group.baseColor, borderColor != .clear {
                storyHeaderView.detailView.groupProPicContainerView.borderColor = story?.group.groupBorderColor
                storyHeaderView.detailView.groupProPicContainerView.borderWidth = 3.toCGFloat.relativeToIphone8Width()
            }
            if let picture = story?.group.imageName, picture.isNotUrlLink {
                storyHeaderView.detailView.groupImageView.setImage(url: picture, firebaseLocation: .groupPictures, resolution: .twoHundred)
            }
            else {
                storyHeaderView.detailView.groupImageView.image = #imageLiteral(resourceName: "map-user-head-ic")
            }
        }
    }
    
    //MARK: - Overriden functions
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollview.frame = bounds
        loadUIElements()
        installLayoutConstraints()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        direction = .forward
        clearScrollViewGarbages()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func commentCountUpdated(_ notification: NSNotification) {
        guard let countTuple = notification.object as? (String, Int) else { return }
        let key = countTuple.0
        let count = countTuple.1
        guard let storyObj = self.story, var post = storyObj.posts.first(where: {$0.postKey == key }), let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == key}) else { return }
        post.commentsCount = count
        story?.posts[postIndex] = post
        self.fillFooterView(withSnap: post)
    }
    
    @objc private func postUpdated(_ notification: NSNotification) {
        guard let post = notification.object as? OrbisFeedPost else { return }
        if let storyIndex = self.story?.posts.firstIndex(where: {$0.postKey == post.postKey}) {
            self.story?.posts[storyIndex] = post
            self.fillFooterView(withSnap: post)
        }
    }
    
    //MARK: - Private functions
    
    private func fillFooterView(withSnap snap: OrbisFeedPost) {
        self.hideLargeTextView()
        if let proPicLink = snap.user?.proPicLink, !proPicLink.isEmpty {
            storyFooterView.userImageView.setImage(url: proPicLink, firebaseLocation: .profilePictures, resolution: .twoHundred)
        }
        else {
            storyFooterView.userImageView.image = #imageLiteral(resourceName: "map-user-head-ic")
        }
        storyFooterView.resetDescriptionLabel()
        if snap.postType == .textPost {
            storyFooterView.postDescriptionLabel.isHidden = true
            storyFooterView.postDescriptionLabel.text = ""
            storyFooterView.readMoreBtn.isHidden = true
        }
        else {
            let desc = snap.details ?? ""
            storyFooterView.postDescriptionLabel.isHidden = desc.isEmpty
            storyFooterView.postDescriptionLabel.text = desc
            storyFooterView.updateReadMoreVisibility()
        }
        
        storyFooterView.userFullNameLabel.text = snap.user?.userDisplayName ?? AppStrings.orbisUser
        storyFooterView.likeCountLabel.text = "\(snap.likeCount)"
        storyFooterView.commentCountLabel.text = "\(snap.commentCount)"
    }
    
    private func fillHeaderView(withSnap snap: OrbisFeedPost) {
        storyHeaderView.detailView.datePostedLabel.text = Date.fromString(string: snap.timestamp ?? "", with: ISOCommonFormatter.shared)?.dateString(DateFormat.postDateTimestampFormat.rawValue) ?? ""
        storyHeaderView.detailView.postLocationLabel.text = snap.location
        storyHeaderView.detailView.locationStackView.isHidden = snap.location.isEmpty
    }
    
    private func likeUnlikePost(post: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        if post.hasLiked == true {
            if let storyIndex = self.story?.posts.firstIndex(where: {$0.postKey == post.postKey}) {
                var updatedPost = post
                updatedPost.hasLiked = false
                updatedPost.decrementLike()
                self.story?.posts[storyIndex] = post
                self.fillFooterView(withSnap: post)
            }
            OrbisSharedPostLikeCommentManager.shared.unlikePost(key: post.postKey!) { data, error in
                if let post = data as? OrbisFeedPost, let storyIndex = self.story?.posts.firstIndex(where: {$0.postKey == post.postKey}) {
                    self.story?.posts[storyIndex] = post
                    self.fillFooterView(withSnap: post)
                }
            }
        }
        else {
            if let storyIndex = self.story?.posts.firstIndex(where: {$0.postKey == post.postKey}) {
                var updatedPost = post
                updatedPost.hasLiked = true
                updatedPost.incrementLike()
                self.story?.posts[storyIndex] = post
                self.fillFooterView(withSnap: post)
            }
            OrbisSharedPostLikeCommentManager.shared.likePost(key: post.postKey!) { data, error in
                if let post = data as? OrbisFeedPost, let storyIndex = self.story?.posts.firstIndex(where: {$0.postKey == post.postKey}) {
                    self.story?.posts[storyIndex] = post
                    self.fillFooterView(withSnap: post)
                }
            }
        }
    }
    
    private func loadUIElements() {
        scrollview.delegate = self
        scrollview.isPagingEnabled = true
        scrollview.backgroundColor = .black
        contentView.addSubview(scrollview)
        contentView.addSubview(storyHeaderView)
        contentView.addSubview(storyFooterView)
        storyFooterView.onUserTapped = {
            [weak self] in
            guard let self = self else { return }
            guard let user = self.story?.posts[self.getSnapIndex].user else { return }
            self.showUserProfile(user: user)
        }
        storyFooterView.onLikeTapped = {
            [weak self] in
            guard let self = self else { return }
            guard let post = self.story?.posts[self.getSnapIndex] else { return }
            self.likeUnlikePost(post: post)
        }
        storyFooterView.onCommentTapped = {
            [weak self] in
            guard let self = self else { return }
            guard let post = self.story?.posts[self.getSnapIndex] else { return }
            self.showCommentView(post: post)
        }
        self.addGestureRecognizer(longPress_gesture)
        self.addGestureRecognizer(tap_gesture)
    }
    private func installLayoutConstraints() {
        //Setting constraints for scrollview
        NSLayoutConstraint.activate([
            scrollview.igLeftAnchor.constraint(equalTo: contentView.igLeftAnchor),
            contentView.igRightAnchor.constraint(equalTo: scrollview.igRightAnchor),
            scrollview.igTopAnchor.constraint(equalTo: contentView.igTopAnchor),
            contentView.igBottomAnchor.constraint(equalTo: scrollview.igBottomAnchor),
            scrollview.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0),
            scrollview.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 1.0)
        ])
        NSLayoutConstraint.activate([
            storyHeaderView.igLeftAnchor.constraint(equalTo: contentView.igLeftAnchor),
            contentView.igRightAnchor.constraint(equalTo: storyHeaderView.igRightAnchor),
            storyHeaderView.igTopAnchor.constraint(equalTo: contentView.igTopAnchor)
        ])
        NSLayoutConstraint.activate([
            storyFooterView.igLeftAnchor.constraint(equalTo: contentView.igLeftAnchor),
            contentView.igRightAnchor.constraint(equalTo: storyFooterView.igRightAnchor),
            storyFooterView.igBottomAnchor.constraint(equalTo: contentView.igBottomAnchor)
        ])
    }
    private func createSnapView(mimeType: OrbisPostType) -> OrbisStoryStaticSnapView {
        let snapView = OrbisStoryStaticSnapView(mimeType: mimeType)
        snapView.translatesAutoresizingMaskIntoConstraints = false
        snapView.tag = snapIndex + snapViewTagIndicator
        snapView.clipsToBounds = true
        /**
         Delete if there is any snapview/videoview already present in that frame location. Because of snap delete functionality, snapview/videoview can occupy different frames(created in 2nd position(frame), when 1st postion snap gets deleted, it will move to first position) which leads to weird issues.
         - If only snapViews are there, it will not create any issues.
         - But if story contains both image and video snaps, there will be a chance in same position both snapView and videoView gets created.
         - That's why we need to remove if any snap exists on the same position.
         */
        scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first?.removeFromSuperview()
        
        scrollview.addSubview(snapView)
        
        /// Setting constraints for snap view.
        NSLayoutConstraint.activate([
            snapView.leadingAnchor.constraint(equalTo: (snapIndex == 0) ? scrollview.leadingAnchor : scrollview.subviews[previousSnapIndex].trailingAnchor),
            snapView.igTopAnchor.constraint(equalTo: scrollview.igTopAnchor),
            snapView.widthAnchor.constraint(equalTo: scrollview.widthAnchor),
            snapView.heightAnchor.constraint(equalTo: scrollview.heightAnchor),
            scrollview.igBottomAnchor.constraint(equalTo: snapView.igBottomAnchor)
        ])
        if(snapIndex == story!.snapsCount - 1) {
            NSLayoutConstraint.activate([
                scrollview.trailingAnchor.constraint(equalTo: snapView.trailingAnchor)
//                snapView.leadingAnchor.constraint(equalTo: scrollview.leadingAnchor, constant: CGFloat(snapIndex)*scrollview.width)
            ])
        }
        return snapView
    }
    private func getSnapview() -> OrbisStoryStaticSnapView? {
        if let imageView = scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first as? OrbisStoryStaticSnapView {
            return imageView
        }
        return nil
    }
    private func createVideoView() -> OrbisStoryVideoSnapView {
        let videoView = OrbisStoryVideoSnapView(mimeType: .videoPost, playerObserverDelegate: self)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.tag = snapIndex + snapViewTagIndicator
        videoView.playerObserverDelegate = self
        videoView.clipsToBounds = true
        /**
         Delete if there is any snapview/videoview already present in that frame location. Because of snap delete functionality, snapview/videoview can occupy different frames(created in 2nd position(frame), when 1st postion snap gets deleted, it will move to first position) which leads to weird issues.
         - If only snapViews are there, it will not create any issues.
         - But if story contains both image and video snaps, there will be a chance in same position both snapView and videoView gets created.
         - That's why we need to remove if any snap exists on the same position.
         */
        scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first?.removeFromSuperview()
        
        scrollview.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.leadingAnchor.constraint(equalTo: (snapIndex == 0) ? scrollview.leadingAnchor : scrollview.subviews[previousSnapIndex].trailingAnchor),
            videoView.igTopAnchor.constraint(equalTo: scrollview.igTopAnchor),
            videoView.widthAnchor.constraint(equalTo: scrollview.widthAnchor),
            videoView.heightAnchor.constraint(equalTo: scrollview.heightAnchor),
            scrollview.igBottomAnchor.constraint(equalTo: videoView.igBottomAnchor)
        ])
        if(snapIndex == story!.snapsCount - 1) {
            NSLayoutConstraint.activate([
                scrollview.trailingAnchor.constraint(equalTo: videoView.trailingAnchor)
            ])
        }
        return videoView
    }
    private func getVideoView(with index: Int) -> OrbisStoryVideoSnapView? {
        if let videoView = scrollview.subviews.filter({$0.tag == index + snapViewTagIndicator}).first as? OrbisStoryVideoSnapView {
            return videoView
        }
        return nil
    }
    
    private func startRequest(snapView: OrbisStoryStaticSnapView, with url: String, snap: OrbisFeedPost) {
        snapView.imageView.image = nil
        self.removeRetryButton()
        snapView.postDescriptionLabel.text = ""
        snapView.postDescriptionLabel.isHidden = true
        if url.isEmpty {
            let image = UIImage(color: .black)
            snapView.imageView.image = image
            snapView.postDescriptionLabel.text = snap.details
            snapView.postDescriptionLabel.isHidden = (snap.details ?? "").isEmpty
            DispatchQueue.main.async {
                [weak self] in
                guard let strongSelf = self else { return}
                strongSelf.startProgressors()
            }
        }
        else {
            snapView.imageView.setImage(url: url, style: .squared, firebaseLocation: .postImages) { result in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return}
                    switch result {
                        case .success(_):
                            /// Start progressor only if handpickedSnapIndex matches with snapIndex and the requested image url should be matched with current snapIndex imageurl
                            if(strongSelf.handpickedSnapIndex == strongSelf.snapIndex && url == strongSelf.story!.posts[strongSelf.snapIndex].mediaUrls?.first) {
                                strongSelf.startProgressors()
                            }
                            else {
                                debugPrint("Mismatching something in story")
                            }
                        case .failure(_):
                            strongSelf.showRetryButton(with: url, for: snapView)
                    }
                }
            }
        }
    }
    
    private func showRetryButton(with url: String, for snapView: OrbisStoryStaticSnapView) {
        snapView.postDescriptionLabel.isHidden = true
        self.retryBtn = IGRetryLoaderButton.init(withURL: url)
        self.retryBtn.translatesAutoresizingMaskIntoConstraints = false
        self.retryBtn.delegate = self
        self.retryBtn.contentSuperView = snapView
        self.isUserInteractionEnabled = true
        self.addSubview(self.retryBtn)
        NSLayoutConstraint.activate([
            self.retryBtn.igCenterXAnchor.constraint(equalTo: snapView.igCenterXAnchor),
            self.retryBtn.igCenterYAnchor.constraint(equalTo: snapView.igCenterYAnchor)
        ])
    }
    private func startPlayer(videoView: OrbisStoryVideoSnapView, with url: String, snap: OrbisFeedPost) {
        videoView.postDescriptionLabel.text = snap.details
        videoView.postDescriptionLabel.isHidden = true
        self.removeRetryButton()
        if scrollview.subviews.count > 0 {
            if story?.isCompletelyVisible == true {
                videoView.videoLayer.startAnimating()
                //                IGVideoCacheManager.shared.getFile(for: url) { [weak self] (result) in
                //                    guard let strongSelf = self else { return }
                //                    switch result {
                //                        case .success(let videoURL):
                //                            /// Start progressor only if handpickedSnapIndex matches with snapIndex
                //                            if(strongSelf.handpickedSnapIndex == strongSelf.snapIndex) {
                //                                let videoResource = VideoResource(filePath: videoURL.absoluteString)
                //                                videoView.videoLayer.play(with: videoResource)
                //                        }
                //                        case .failure(let error):
                //                            videoView.videoLayer.stopAnimating()
                //                            debugPrint("Video error: \(error)")
                //                    }
                //                }
                if(self.handpickedSnapIndex == self.snapIndex) {
                    let videoResource = VideoResource(filePath: url)
                    videoView.videoLayer.play(with: videoResource)
                }
            }
        }
    }
    @objc private func didLongPress(_ sender: UILongPressGestureRecognizer) {
        longPressGestureState = sender.state
        if sender.state == .began ||  sender.state == .ended {
            if(sender.state == .began) {
                self.isLongPressGestureActive = true
                pauseEntireSnap()
            } else {
                self.isLongPressGestureActive = false
                resumeEntireSnap()
            }
        }
    }
    @objc private func didTapSnap(_ sender: UITapGestureRecognizer) {
        showStoryHeaderFooterViews()
        let touchLocation = sender.location(ofTouch: 0, in: self.scrollview)
        if let snapCount = story?.snapsCount {
            var n = snapIndex
            if let _ = getVideoView(with: n) {
                stopPlayer()
            }
            /*!
             * Based on the tap gesture(X) setting the direction to either forward or backward
             */
            if let snap = story?.posts[n], (snap.postType == .imagePost || snap.postType == .textPost), getSnapview()?.imageView.image == nil {
                //Remove retry button if tap forward or backward if it exists
                if let snapView = getSnapview(), let btn = retryBtn, self.subviews.contains(btn) {
                    snapView.removeRetryButton()
                    self.removeRetryButton()
                }
                fillupLastPlayedSnap(n)
            }else {
                //Remove retry button if tap forward or backward if it exists
                if let videoView = getVideoView(with: n), let btn = retryBtn, self.subviews.contains(btn) {
                    videoView.removeRetryButton()
                    self.removeRetryButton()
                }
                if getVideoView(with: n)?.videoLayer.player?.timeControlStatus != .playing {
                    fillupLastPlayedSnap(n)
                }
            }
            if touchLocation.x < scrollview.contentOffset.x + (scrollview.frame.width/2) {
                direction = .backward
                if snapIndex >= 1 && snapIndex <= snapCount {
                    clearLastPlayedSnaps(n)
                    stopSnapProgressors(with: n)
                    n -= 1
                    resetSnapProgressors(with: n)
                    willMoveToPreviousOrNextSnap(n: n)
                } else {
                    delegate?.moveToPreviousStory()
                }
            } else {
                if snapIndex >= 0 && snapIndex <= snapCount {
                    //Stopping the current running progressors
                    stopSnapProgressors(with: n)
                    direction = .forward
                    n += 1
                    willMoveToPreviousOrNextSnap(n: n)
                }
            }
        }
    }
    
    private func addLargeTextViewer() {
        guard let text = story?.posts[snapIndex].details, !text.isEmpty else{
            hideLargeTextView()
            return
        }
        let slv = StoryLargeTextViewer()
        slv.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        slv.isUserInteractionEnabled = true
        slv.translatesAutoresizingMaskIntoConstraints = false
        slv.descriptionLabel.text = text
        let labelWidth = UIScreen.main.bounds.width - 30.toCGFloat.relativeToIphone8Width()
        let fontHeight = 14.toCGFloat.relativeToIphone8Width()
        let font = slv.descriptionLabel.font.withSize(fontHeight)
        let maxHeight = (UIScreen.main.bounds.height * 0.7)
        var height = text.height(withConstrainedWidth: labelWidth, font: font) + 70.toCGFloat.relativeToIphone8Width() // 70 is height of readless button and stack view padding and margin
        if height > maxHeight {
            height = maxHeight
        }
        slv.scrollViewHeightConstraint.constant = height
        slv.layoutIfNeeded()
        slv.isHidden = true
        self.storyLargeTextViewer = slv
        self.contentView.addSubview(storyLargeTextViewer!)
        NSLayoutConstraint.activate([
            storyLargeTextViewer!.igLeftAnchor.constraint(equalTo: self.contentView.igLeftAnchor),
            self.contentView.igRightAnchor.constraint(equalTo: storyLargeTextViewer!.igRightAnchor),
            storyLargeTextViewer!.heightAnchor.constraint(equalTo: self.contentView.heightAnchor)
        ])
        self.storyLargeTVBottomConstraint = storyLargeTextViewer?.igBottomAnchor.constraint(equalTo: self.contentView.igBottomAnchor)
        self.storyLargeTextViewer?.isHidden = false
        self.storyLargeTextViewer?.onReadLessTapped = {
            [weak self] in
            self?.hideLargeTextView()
        }
    }
    
    private func removeStoryLargeTextViewer() {
        storyLargeTextViewer?.removeFromSuperview()
        storyLargeTVBottomConstraint = nil
        storyLargeTextViewer = nil
    }
    
    private func showLargeTextView() {
        self.pauseEntireSnap()
        removeStoryLargeTextViewer()
        addLargeTextViewer()
    }
    
    private func hideLargeTextView() {
        self.resumeEntireSnap()
        removeStoryLargeTextViewer()
        storyFooterView.showDescriptionStack()
    }
    
    private func showGroupDetails(group: Group) {
        self.stopEntireSnap()
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: group)
        delegate?.pushViewController(viewController: groupDetailsVC)
    }
    
    private func showUserProfile(user: OrbisUser) {
        if user.deleted == true {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        self.stopEntireSnap()
        let isViewingSelf = (user.userKey == UserSessionManager.shared.currentUser?.userKey)
        let profileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        profileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: isViewingSelf)
        delegate?.pushViewController(viewController: profileVC)
    }
    
    private func showCommentView(post: OrbisFeedPost) {
        self.stopEntireSnap()
        let postCommentsVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "postCommentsVC") as! CommentsViewController
        let navVC = OrbisNavigationController(rootViewController: postCommentsVC)
        navVC.modalPresentationStyle = .overFullScreen
        postCommentsVC.viewModel = PostCommentsViewModel(post: post)
        delegate?.panPresentViewController(viewController: navVC)
    }
    
    func restartSnap() {
        hasStoryBeenStopped = false
        let snapIndexVal = self.snapIndex
        self.snapIndex = snapIndexVal
    }
    
    func stopEntireSnap() {
        hasStoryBeenStopped = true
        if let snap = story?.posts[snapIndex] {
            if snap.postType == .videoPost {
                stopPlayer()
            }
        }
        resetSnapProgressors(with: snapIndex)
    }
    
    @objc private func didEnterForeground() {
        if let snap = story?.posts[snapIndex] {
            if snap.postType == .videoPost {
                let videoView = getVideoView(with: snapIndex)
                startPlayer(videoView: videoView!, with: snap.signedUrls?.first ?? "", snap: snap)
            }else {
                startSnapProgress(with: snapIndex)
            }
        }
    }
    @objc private func didEnterBackground() {
        if let snap = story?.posts[snapIndex] {
            if snap.postType == .videoPost {
                stopPlayer()
            }
        }
        resetSnapProgressors(with: snapIndex)
    }
    private func willMoveToPreviousOrNextSnap(n: Int) {
        if let count = story?.snapsCount {
            if n < count {
                //Move to next or previous snap based on index n
                let x = n.toFloat * frame.width
                let offset = CGPoint(x: x,y: 0)
                scrollview.setContentOffset(offset, animated: false)
                story?.lastPlayedSnapIndex = n
                handpickedSnapIndex = n
                snapIndex = n
                if let shouldPause = delegate?.didFinishPlayingStory(), shouldPause {
                    
                }
                // add counter
            } else {
                delegate?.didCompletePreview()
            }
        }
    }
    @objc private func didCompleteProgress() {
        let n = snapIndex + 1
        if let count = story?.snapsCount {
            if n < count {
                //Move to next snap
                let x = n.toFloat * frame.width
                let offset = CGPoint(x: x,y: 0)
                scrollview.setContentOffset(offset, animated: false)
                story?.lastPlayedSnapIndex = n
                direction = .forward
                handpickedSnapIndex = n
                snapIndex = n
                if let shouldPause = delegate?.didFinishPlayingStory(), shouldPause {
                    
                }
                // ad counter
            }else {
                stopPlayer()
                delegate?.didCompletePreview()
            }
        }
    }
    private func fillUpMissingImageViews(_ sIndex: Int) {
        if sIndex != 0 {
            for i in 0..<sIndex {
                snapIndex = i
            }
            let xValue = sIndex.toFloat * scrollview.frame.width
            scrollview.contentOffset = CGPoint(x: xValue, y: 0)
        }
    }
    //Before progress view starts we have to fill the progressView
    private func fillupLastPlayedSnap(_ sIndex: Int) {
        if let snap = story?.posts[sIndex], snap.postType == .videoPost {
            videoSnapIndex = sIndex
            stopPlayer()
        }
        if let holderView = self.getProgressIndicatorView(with: sIndex),
            let progressView = self.getProgressView(with: sIndex){
            progressView.igWidthConstraint?.isActive = false
            progressView.igWidthConstraint = progressView.widthAnchor.constraint(equalTo: holderView.widthAnchor, multiplier: 1.0)
            progressView.igWidthConstraint?.isActive = true
        }
    }
    private func fillupLastPlayedSnaps(_ sIndex: Int) {
        //Coz, we are ignoring the first.snap
        if sIndex != 0 {
            for i in 0..<sIndex {
                if let holderView = self.getProgressIndicatorView(with: i),
                    let progressView = self.getProgressView(with: i){
                    progressView.igWidthConstraint?.isActive = false
                    progressView.igWidthConstraint = progressView.widthAnchor.constraint(equalTo: holderView.widthAnchor, multiplier: 1.0)
                    progressView.igWidthConstraint?.isActive = true
                }
            }
        }
    }
    private func clearLastPlayedSnaps(_ sIndex: Int) {
        if let _ = self.getProgressIndicatorView(with: sIndex),
            let progressView = self.getProgressView(with: sIndex) {
            progressView.igWidthConstraint?.isActive = false
            progressView.igWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
            progressView.igWidthConstraint?.isActive = true
        }
    }
    private func clearScrollViewGarbages() {
        scrollview.contentOffset = CGPoint(x: 0, y: 0)
        if scrollview.subviews.count > 0 {
            var i = 0 + snapViewTagIndicator
            var snapViews = [UIView]()
            scrollview.subviews.forEach({ (imageView) in
                if imageView.tag == i {
                    snapViews.append(imageView)
                    i += 1
                }
            })
            if snapViews.count > 0 {
                snapViews.forEach({ (view) in
                    view.removeFromSuperview()
                })
            }
        }
    }
    private func gearupTheProgressors(type: OrbisPostType, playerView: OrbisStoryVideoSnapView? = nil) {
        if let holderView = getProgressIndicatorView(with: snapIndex),
            let progressView = getProgressView(with: snapIndex){
            progressView.story_identifier = self.story?.group.groupKey
            progressView.snapIndex = snapIndex
            if let key = self.story?.posts[snapIndex].postKey {
                self.delegate?.didSeenStory(postKey: key)
            }
            DispatchQueue.main.async {
                if type == .imagePost || type == .textPost {
                    progressView.start(with: 5.0, holderView: holderView, completion: { [weak self] (identifier, snapIndex, isCancelledAbruptly) in
                        print("Completed snapindex: \(snapIndex)")
                        if isCancelledAbruptly == false && self?.hasStoryBeenStopped == false {
                            self?.didCompleteProgress()
                        }
                    })
                }else {
                    //Handled in delegate methods for videos
                }
            }
        }
    }
    
    //MARK:- Internal functions
    func startProgressors() {
        DispatchQueue.main.async {
            if self.scrollview.subviews.count > 0 {
                let imageView = self.scrollview.subviews.filter{v in v.tag == self.snapIndex + snapViewTagIndicator}.first as? OrbisStoryStaticSnapView
                if imageView?.imageView.image != nil && self.story?.isCompletelyVisible == true {
                    self.gearupTheProgressors(type: .imagePost)
                } else {
                    // Didend displaying will call this startProgressors method. After that only isCompletelyVisible get true. Then we have to start the video if that snap contains video.
                    if self.story?.isCompletelyVisible == true {
                        let videoView = self.scrollview.subviews.filter{v in v.tag == self.snapIndex + snapViewTagIndicator}.first as? OrbisStoryVideoSnapView
                        let snap = self.story?.posts[self.snapIndex]
                        if let vv = videoView, self.story?.isCompletelyVisible == true {
                            self.startPlayer(videoView: vv, with: snap!.signedUrls?.first ?? "", snap: snap!)
                        }
                    }
                }
            }
        }
    }
    func getProgressView(with index: Int) -> IGSnapProgressView? {
        let progressView = storyHeaderView.getProgressView
        if progressView.subviews.count > 0 {
            let pv = getProgressIndicatorView(with: index)?.subviews.first as? IGSnapProgressView
            guard let currentStory = self.story else {
                fatalError("story not found")
            }
            pv?.story = currentStory
            return pv
        }
        return nil
    }
    func getProgressIndicatorView(with index: Int) -> IGSnapProgressIndicatorView? {
        let progressView = storyHeaderView.getProgressView
        return progressView.subviews.filter({v in v.tag == index+progressIndicatorViewTag}).first as? IGSnapProgressIndicatorView ?? nil
    }
    func adjustPreviousSnapProgressorsWidth(with index: Int) {
        fillupLastPlayedSnaps(index)
    }
    func deleteSnap() {
        let progressView = storyHeaderView.getProgressView
        clearLastPlayedSnaps(snapIndex)
        stopSnapProgressors(with: snapIndex)
        
        let snapCount = story?.snapsCount ?? 0
        if let lastIndicatorView = getProgressIndicatorView(with: snapCount-1), let preLastIndicatorView = getProgressIndicatorView(with: snapCount-2) {
            
            lastIndicatorView.constraints.forEach { $0.isActive = false }
            
            preLastIndicatorView.rightConstraiant?.isActive = false
            preLastIndicatorView.rightConstraiant = progressView.igRightAnchor.constraint(equalTo: preLastIndicatorView.igRightAnchor, constant: 8)
            preLastIndicatorView.rightConstraiant?.isActive = true
        } else {
            debugPrint("No Snaps")
        }
        /**
         - If user is going to delete video snap, then we need to stop the player.
         - Remove the videoView/snapView from the scrollview subviews. Because once the snap got deleted, the next snap will be created on that same frame(x,y,width,height). If we didn't remove the videoView/snapView from scrollView subviews then it will create some wierd issues.
         */
        if story?.posts[snapIndex].postType == .videoPost {
            stopPlayer()
        }
        scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first?.removeFromSuperview()
        
        /**
         Once we set isDeleted, snaps and snaps count will be reduced by one. So, instead of snapIndex+1, we need to pass snapIndex to willMoveToPreviousOrNextSnap. But the corresponding progressIndicator is not currently in active. Another possible way is we can always remove last presented progress indicator. So that snapIndex and tag will matches, so that progress indicator starts.
         */
        story?.posts[snapIndex].isDeleted = true
        direction = .forward
        for sIndex in 0..<snapIndex {
            if let holderView = self.getProgressIndicatorView(with: sIndex),
                let progressView = self.getProgressView(with: sIndex){
                progressView.igWidthConstraint?.isActive = false
                progressView.igWidthConstraint = progressView.widthAnchor.constraint(equalTo: holderView.widthAnchor, multiplier: 1.0)
                progressView.igWidthConstraint?.isActive = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3) {[weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.willMoveToPreviousOrNextSnap(n: strongSelf.snapIndex)
        }
        
        //Do the api call, when api request is success remove the snap using snap internal identifier from the nsuserdefaults.
    }
    
    //MARK: - Public functions
    public func willDisplayCellForZerothIndex(with sIndex: Int, handpickedSnapIndex: Int) {
        self.handpickedSnapIndex = handpickedSnapIndex
        story?.isCompletelyVisible = true
        willDisplayCell(with: handpickedSnapIndex)
    }
    public func willDisplayCell(with sIndex: Int) {
        //Todo:Make sure to move filling part and creating at one place
        //Clear the progressor subviews before the creating new set of progressors.
        storyHeaderView.clearTheProgressorSubviews()
        storyHeaderView.createSnapProgressors()
        fillUpMissingImageViews(sIndex)
        fillupLastPlayedSnaps(sIndex)
        snapIndex = sIndex
        
        //Remove the previous observors
        NotificationCenter.default.removeObserver(self)
        
        // Add the observer to handle application from background to foreground
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(commentCountUpdated(_:)), name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postUpdated(_:)), name: NSNotification.Name(AppNotificationKeys.Post.postUpdated), object: nil)
    }
    public func startSnapProgress(with sIndex: Int) {
        if let indicatorView = getProgressIndicatorView(with: sIndex),
            let pv = getProgressView(with: sIndex) {
            if let key = self.story?.posts[snapIndex].postKey {
                self.delegate?.didSeenStory(postKey: key)
            }
            pv.start(with: 5.0, holderView: indicatorView, completion: { (identifier, snapIndex, isCancelledAbruptly) in
                if isCancelledAbruptly == false {
                    self.didCompleteProgress()
                }
            })
        }
    }
    public func pauseSnapProgressors(with sIndex: Int) {
        story?.isCompletelyVisible = false
        getProgressView(with: sIndex)?.pause()
    }
    public func stopSnapProgressors(with sIndex: Int) {
        getProgressView(with: sIndex)?.stop()
        stopPlayer()
    }
    public func resetSnapProgressors(with sIndex: Int) {
        self.getProgressView(with: sIndex)?.reset()
    }
    public func pausePlayer(with sIndex: Int) {
        getVideoView(with: sIndex)?.videoLayer.pause()
    }
    public func stopPlayer() {
        let videoView = getVideoView(with: videoSnapIndex)
        if videoView?.videoLayer.player?.timeControlStatus != .playing {
            getVideoView(with: videoSnapIndex)?.videoLayer.player?.replaceCurrentItem(with: nil)
        }
        videoView?.videoLayer.stop()
//        getVideoView(with: videoSnapIndex)?.videoLayer.player = nil
    }
    public func resumePlayer(with sIndex: Int) {
        if self.storyLargeTextViewer == nil {
            getVideoView(with: sIndex)?.videoLayer.play()
        }
    }
    public func didEndDisplayingCell() {
        
    }
    public func resumePreviousSnapProgress(with sIndex: Int) {
        if self.storyLargeTextViewer == nil {
            getProgressView(with: sIndex)?.resume()
        }
    }
    public func tryResumeSnap(with sIndex: Int) {
        story?.isCompletelyVisible = true
        if self.storyLargeTextViewer == nil {
            resumePreviousSnapProgress(with: sIndex)
            resumePlayer(with: sIndex)
        }
    }
    public func pauseEntireSnap() {
        let v = getProgressView(with: snapIndex)
        let videoView = scrollview.subviews.filter{v in v.tag == snapIndex + snapViewTagIndicator}.first as? OrbisStoryVideoSnapView
        if videoView != nil {
            v?.pause()
            videoView?.videoLayer.pause()
        }else {
            v?.pause()
        }
        hideStoryHeaderFooterViews()

    }
    public func resumeEntireSnap() {
        let v = getProgressView(with: snapIndex)
        let videoView = scrollview.subviews.filter{v in v.tag == snapIndex + snapViewTagIndicator}.first as? OrbisStoryVideoSnapView
        if videoView != nil {
            v?.resume()
            videoView?.videoLayer.play()
        }else {
            v?.resume()
        }
        showStoryHeaderFooterViews()
    }
    
    private func hideStoryHeaderFooterViews() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4, delay: 0.5) { [weak self] in
                guard let self = self else { return }
                guard self.isLongPressGestureActive else {
                    self.showStoryHeaderFooterViews()
                    return
                }
                self.storyHeaderView.alpha = 0
                self.storyFooterView.alpha = 0
            } completion: { [weak self] (success) in
                guard let self = self else { return }
                guard self.isLongPressGestureActive else {
                    self.showStoryHeaderFooterViews()
                    return
                }
                self.storyHeaderView.isHidden = true
                self.storyFooterView.isHidden = true
            }
        }
    }
    
    private func showStoryHeaderFooterViews() {
        self.storyHeaderView.isHidden = false
        self.storyFooterView.isHidden = false
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4, delay: 0) { [weak self] in
                self?.storyHeaderView.alpha = 1
                self?.storyFooterView.alpha = 1
            } completion: { (success) in
            }
        }
    }
    //Used the below function for image retry option
    public func retryRequest(view: UIView, with url: String) {
        let snap = story!.posts[snapIndex]
        if let v = view as? OrbisStoryStaticSnapView  {
            v.removeRetryButton()
            self.removeRetryButton()
            self.startRequest(snapView: v, with: url, snap: snap)
        }else if let v = view as? OrbisStoryVideoSnapView {
            v.removeRetryButton()
            self.removeRetryButton()
            self.startPlayer(videoView: v, with: url, snap: snap)
        }
    }
}

//MARK: - Extension|StoryPreviewHeaderProtocol
extension OrbisStoryPreviewCell: StoryPreviewHeaderProtocol {
    func didTapCloseButton() {
        delegate?.didTapCloseButton()
    }
    func groupTapped() {
        guard let group = self.story?.group else { return }
        self.showGroupDetails(group: group)
    }
}

//MARK: - Extension|RetryBtnDelegate
extension OrbisStoryPreviewCell: RetryBtnDelegate {
    func retryButtonTapped() {
        self.retryRequest(view: retryBtn.contentSuperView!, with: retryBtn.contentURL!)
    }
}

//MARK: - Extension|IGPlayerObserverDelegate
extension OrbisStoryPreviewCell: IGPlayerObserver {
    
    func didStartPlaying() {
        if let videoView = getVideoView(with: snapIndex) {
            if videoView.videoLayer.error == nil && (story?.isCompletelyVisible)! == true {
                if let holderView = getProgressIndicatorView(with: snapIndex),
                    let progressView = getProgressView(with: snapIndex) {
                    progressView.story_identifier = self.story?.group.groupKey
                    progressView.snapIndex = snapIndex
                    if let key = self.story?.posts[snapIndex].postKey {
                        self.delegate?.didSeenStory(postKey: key)
                    }
                    if let duration = videoView.videoLayer.currentItem?.asset.duration {
                        if Float(duration.value) > 0 {
                            progressView.start(with: duration.seconds - Double(videoView.videoLayer.currentTime), holderView: holderView, completion: {(identifier, snapIndex, isCancelledAbruptly) in
                                if isCancelledAbruptly == false {
                                    self.videoSnapIndex = snapIndex
                                    self.stopPlayer()
                                    self.didCompleteProgress()
                                } else {
                                    self.videoSnapIndex = snapIndex
                                    self.stopPlayer()
                                }
                            })
                        }else {
                            debugPrint("Player error: Unable to play the video")
                        }
                    }
                }
            }
        }
    }
    func didFailed(withError error: String, for url: URL?) {
        debugPrint("Failed with error: \(error)")
        if let videoView = getVideoView(with: snapIndex), let videoURL = url {
            self.retryBtn = IGRetryLoaderButton(withURL: videoURL.absoluteString)
            self.retryBtn.translatesAutoresizingMaskIntoConstraints = false
            self.retryBtn.delegate = self
            self.retryBtn.contentSuperView = videoView
            self.isUserInteractionEnabled = true
            self.addSubview(self.retryBtn)
            NSLayoutConstraint.activate([
                self.retryBtn.igCenterXAnchor.constraint(equalTo: videoView.igCenterXAnchor),
                self.retryBtn.igCenterYAnchor.constraint(equalTo: videoView.igCenterYAnchor)
            ])
        }
    }
    func didCompletePlay() {
        //Video completed
    }
    
    func didTrack(progress: Float) {
        //Delegate already handled. If we just print progress, it will print the player current running time
    }
}

extension OrbisStoryPreviewCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if(gestureRecognizer is UISwipeGestureRecognizer) {
//            return true
//        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == storyLargeTextViewer?.scrollView {
            return true
        }
        return false
    }
}

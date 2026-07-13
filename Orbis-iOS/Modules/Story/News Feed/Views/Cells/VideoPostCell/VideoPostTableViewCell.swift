//
//  VideoPostTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 31/05/2021.
//

import UIKit
import AVKit
import FirebaseStorageUI

class VideoPostTableViewCell: UITableViewCell {

    @IBOutlet weak var postOwnerProPicView: UIImageView!
    @IBOutlet weak var postOwnerProPicContainer: RoundedView!
    @IBOutlet weak var postOwnerNameLabel: UILabel!
    @IBOutlet weak var postedDateLabel: UILabel!
    @IBOutlet weak var postedLocationLabel: UILabel!
    @IBOutlet weak var locationStackView: UIStackView!
    
    
    @IBOutlet weak var descriptionLabel: OrbisActiveLabel!
    @IBOutlet weak var videoViewContainer: UIView!
    
    @IBOutlet weak var likeIconView: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentIconView: UIImageView!
    @IBOutlet weak var commentCountLabel: UILabel!

    @IBOutlet weak var bottomUserInfoView: UIStackView!
    @IBOutlet weak var bottomStackViewSpacer: UIView!
    @IBOutlet weak var moreBtnView: UIView!
    @IBOutlet weak var likeStackView: UIStackView!
    @IBOutlet weak var commentStackView: UIStackView!
    
    
    @IBOutlet weak var subPosterNameLabel: UILabel!
    @IBOutlet weak var subPosterImageView: UIImageView!
    
    @IBOutlet weak var richTextContentStack: UIStackView!
    @IBOutlet weak var externalUrlImageView: UIImageView!
    @IBOutlet weak var externalUrlDomainLabel: UILabel!
    @IBOutlet weak var externalUrlTitleLabel: UILabel!
    @IBOutlet weak var externalUrlDescriptionLabel: UILabel!
    @IBOutlet weak var viewMoreBtn: UIButton!
    
    @IBAction func moreTapped(_ sender: Any) {
        actionDelegate?.didTapMore(onCell: self, tappedView: moreBtnView, post: viewModel.model)
    }
    
    @IBAction func expandTextTapped(_ sender: Any) {
        var newPost = viewModel.model!
        newPost.isDescriptionExpanded = !newPost.isDescriptionExpanded
        actionDelegate?.didTapViewMore(onCell: self, post: newPost, maxLines: descriptionLabel.calculateMaxLines())
    }
    
    var sliderCurrentIndex: Int = 0
    var isTap = true
    
    var viewModel: VideoPostCellViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    var videoActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    weak var actionDelegate: PostCellActionDelegate?
    var onVideoStartedPlaying: ((VideoPostTableViewCell?) -> Void)?
    
    private var playerRateObserver: NSKeyValueObservation?
    
    var thumbnailOverlay = UIImageView()

    var player: AVPlayer?
    var playerVC: AVPlayerViewController?
//    var contextVar = 0
    var isRateObserving = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCommentStack(_:)))
        commentStackView.isUserInteractionEnabled = true
        commentStackView.addGestureRecognizer(commentTapGesture)
        
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLikeStack(_:)))
        likeIconView.isUserInteractionEnabled = true
        likeIconView.addGestureRecognizer(likeTapGesture)
        
        let richContentTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapRichContent(_:)))
        richTextContentStack.isUserInteractionEnabled = true
        richTextContentStack.addGestureRecognizer(richContentTapGesture)
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLocationStack(_:)))
        locationStackView.isUserInteractionEnabled = true
        locationStackView.addGestureRecognizer(locationTapGesture)
        
        let postOwnerNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        let postOwnerPicTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        postOwnerNameLabel.isUserInteractionEnabled = true
        postOwnerNameLabel.addGestureRecognizer(postOwnerNameTapGesture)
        postOwnerProPicContainer.isUserInteractionEnabled = true
        postOwnerProPicContainer.addGestureRecognizer(postOwnerPicTapGesture)
        
        let postUserStackTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostUser(_:)))
        bottomUserInfoView.isUserInteractionEnabled = true
        bottomUserInfoView.addGestureRecognizer(postUserStackTapGesture)
        
        videoActivityIndicator.color = .white
        videoActivityIndicator.hidesWhenStopped = true
        videoViewContainer.addSubview(videoActivityIndicator)
        videoActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoActivityIndicator.centerXAnchor.constraint(equalTo: videoViewContainer.centerXAnchor),
            videoActivityIndicator.centerYAnchor.constraint(equalTo: videoViewContainer.centerYAnchor)
        ])
    }
    
    deinit {
//        if isRateObserving {
//            DispatchQueue.main.async {
//                self.player?.removeObserver(self, forKeyPath: "rate", context: &self.contextVar)
//            }
//        }
        playerRateObserver?.invalidate()
        playerVC?.view.removeFromSuperview()
        removeAllSubViews()
    }
    
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if context == &self.contextVar {
//            guard let objPlayer = object as? AVPlayer, objPlayer == self.player else {
//                return
//            }
//            if objPlayer.rate > 0 {
//                self.removeThumbnailOverlay()
//                self.onVideoStartedPlaying?(self)
//            }
//        }
//    }
    
    private func addThumbnailOverlay() {
        guard let view = playerVC?.contentOverlayView else { return }
        guard let videoThumbLink = viewModel.videoThumbnailLink else { return }
        thumbnailOverlay.removeFromSuperview()
        thumbnailOverlay = UIImageView(frame: videoViewContainer.bounds)
        thumbnailOverlay.backgroundColor = .clear
        thumbnailOverlay.contentMode = .scaleAspectFit
        view.addSubview(thumbnailOverlay)
        thumbnailOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbnailOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbnailOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            thumbnailOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        thumbnailOverlay.sd_setImage(with: videoThumbLink, placeholderImage: nil)
    }
    
    private func removeThumbnailOverlay() {
        thumbnailOverlay.removeFromSuperview()
    }
    
    @objc private func didTapPostUser(_ gesture: UIGestureRecognizer) {
        guard let user = viewModel.model.user else { return }
        actionDelegate?.didTapUserStack(onCell: self, user: user)
    }
    
    @objc private func didTapPostOwner(_ gesture: UIGestureRecognizer) {
        guard let group = viewModel.model.group else {
            if let user = viewModel.model.user {
                actionDelegate?.didTapUserStack(onCell: self, user: user)
            }
            return
        }
        actionDelegate?.didTapGroupName(onCell: self, group: group)
    }
    
    @objc private func didTapLocationStack(_ gesture: UIGestureRecognizer) {
        guard let place = viewModel.model.place else { return }
        actionDelegate?.didTapLocationStack(onCell: self, place: place)
    }
    
    @objc private func didTapCommentStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapCommentStack(onCell: self, post: viewModel.model)
    }
    
    @objc private func didTapLikeStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapLikeStack(onCell: self, post: viewModel.model)
    }

    @objc private func didTapRichContent(_ gesture: UIGestureRecognizer) {
        guard let urlString = viewModel.richContent?.originalUrl, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateViewContent() {
        postOwnerProPicContainer.borderColor = viewModel.posterBaseColor
        postOwnerNameLabel.text = viewModel.posterFullName
        postedDateLabel.text = viewModel.datePostedString
        postedLocationLabel.text = viewModel.locationString
        descriptionLabel.text = viewModel.description
        descriptionLabel.isHidden = viewModel.description.isEmpty
        fillRichTextContent()
        let likeColor = viewModel.likeIconColor
        likeIconView.tintColor = likeColor
        likeCountLabel.textColor = likeColor
        likeCountLabel.text = viewModel.likeCountString
        commentCountLabel.text = viewModel.commentCountString
        bottomUserInfoView.isHidden = !viewModel.shouldShowBottomUser
        bottomStackViewSpacer.isHidden = viewModel.shouldShowBottomUser
        locationStackView.isHidden = viewModel.locationString.isEmpty
        fillSubPosterDetail()
        updateProfilePic()
        
        removeAllSubViews()
        addPlayer()
        descriptionLabel.numberOfLines = viewModel.numberOfLines
        viewMoreBtn.isHidden = !(descriptionLabel.calculateMaxLines() > AppValues.postTextMaxLines)
        updateTextMoreBtnText()
    }
    
    private func updateTextMoreBtnText() {
        let title = (descriptionLabel.numberOfLines == 0) ? AppStrings.viewLess : AppStrings.viewMore
        viewMoreBtn.setTitle(title, for: .normal)
    }
    
    private func fillRichTextContent() {
        richTextContentStack.isHidden = !viewModel.hasRichTextContent
        if var imageUrl = viewModel.richContent?.imageUrl, !imageUrl.isEmpty {
            self.externalUrlImageView.isHidden = false
            if !imageUrl.contains("http") && !imageUrl.contains("www.") {
                if let originalUrl = viewModel.richContent?.originalUrl, !originalUrl.isEmpty {
                    imageUrl = originalUrl + "/\(imageUrl)"
                }
            }
            imageUrl = imageUrl.toProperURLString
            externalUrlImageView.sd_setImage(with: URL(string: imageUrl)) {
                [weak self] image, error, _ , _ in
                if image == nil || error != nil {
                    self?.externalUrlImageView.isHidden = true
                }
            }
        }
        else {
            self.externalUrlImageView.isHidden = true
        }
        externalUrlTitleLabel.text = viewModel.richContent?.title ?? ""
        externalUrlDomainLabel.text = viewModel.richContent?.canonicalUrl?.uppercased() ?? ""
        externalUrlDescriptionLabel.text = viewModel.richContent?.description ?? ""
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.posterProPicLink.isEmpty else {
            postOwnerProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.posterProPicLink
        
        postOwnerProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: (viewModel.model.group != nil) ? .groupPictures : .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func fillSubPosterDetail() {
        subPosterNameLabel.text = viewModel.subPosterFullName
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.subPosterProPicLink.isEmpty else {
            subPosterImageView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.subPosterProPicLink
        subPosterImageView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func removeAllSubViews() {
        videoViewContainer.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        videoViewContainer.layer.sublayers?.forEach({ (layer) in
            if layer.isKind(of: AVPlayerLayer.self) {
                layer.removeFromSuperlayer()
            }
        })
    }

    func addPlayer() {
        var urlStr = ""
        if viewModel.isPendingPost {
            urlStr = viewModel.pendingVideos.first ?? ""
            finalizeVideoSetup(withUrl: urlStr)
        }
        else {
            urlStr = viewModel.mediaUrls.first ?? ""
            videoActivityIndicator.startAnimating()
            viewModel.fetchMediaUrl(forName: urlStr) { [weak self] data, err in
                guard let self = self else { return }
                self.videoActivityIndicator.stopAnimating()
                guard let urlString = data as? String else { return }
                self.finalizeVideoSetup(withUrl: urlString)
            }
        }
    }
    
    private func finalizeVideoSetup(withUrl urlStr: String) {
        if let url = URL(string: urlStr) {
            player = AVPlayer(url: url)
            player?.automaticallyWaitsToMinimizeStalling = false
            playerVC = AVPlayerViewController()
            playerVC?.player = player!
            playerVC?.videoGravity = .resizeAspect
            playerVC?.view.frame.size.height = videoViewContainer.frame.size.height
            playerVC?.view.frame.size.width = videoViewContainer.frame.size.width
//            DispatchQueue.main.async {
//                self.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: &self.contextVar)
//            }
            playerRateObserver = player?.observe(\AVPlayer.rate, options: [.new]) { [weak self] (player, _) in
                guard let self = self else { return }
                // Update playPauseButton type.
                let newRate = player.rate
                if newRate > 0 {
                    self.removeThumbnailOverlay()
                    self.onVideoStartedPlaying?(self)
                }
            }
            addThumbnailOverlay()
//            self.isRateObserving = true
            videoViewContainer.addSubview(playerVC!.view)
            videoViewContainer.bringSubviewToFront(videoActivityIndicator)
        }
        else {
            let text = AppErrorStrings.couldNotLoadVideo
            let label = UILabel()
            label.font = UIFont(name: "Montserrat-Regular", size: CGFloat(10).relativeToIphone8Width())
            label.textColor = UIColor(named: AppColors.appWarmGray2.rawValue)
            label.text = text
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            removeThumbnailOverlay()
            videoViewContainer.addSubview(label)
            let constantVal = CGFloat(10).relativeToIphone8Width()
            label.leadingAnchor.constraint(equalTo: videoViewContainer.leadingAnchor, constant: constantVal).isActive = true
            label.trailingAnchor.constraint(equalTo: videoViewContainer.trailingAnchor, constant: constantVal).isActive = true
            label.centerYAnchor.constraint(equalTo: videoViewContainer.centerYAnchor).isActive = true
        }
    }
    
}

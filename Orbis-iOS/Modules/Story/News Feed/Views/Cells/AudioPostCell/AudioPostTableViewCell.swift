//
//  AudioPostTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit
import SZAVPlayer

enum SZPlayerControllerEventType {
    case none
    case playing
    case paused
    case stalled
    case failed
}

class AudioPostTableViewCell: UITableViewCell {

    @IBOutlet weak var postOwnerProPicView: UIImageView!
    @IBOutlet weak var postOwnerProPicContainer: RoundedView!
    @IBOutlet weak var postOwnerNameLabel: UILabel!
    @IBOutlet weak var postedDateLabel: UILabel!
    @IBOutlet weak var postedLocationLabel: UILabel!

    @IBOutlet weak var audioPlayIconView: UIImageView!
    @IBOutlet weak var audioWaveFormView: UIView!
    @IBOutlet weak var audioLengthLabel: UILabel!
    
    @IBOutlet weak var likeIconView: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentIconView: UIImageView!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    @IBOutlet weak var subPosterNameLabel: UILabel!
    @IBOutlet weak var subPosterImageView: UIImageView!
    @IBOutlet weak var locationStackView: UIStackView!

    @IBOutlet weak var bottomUserInfoView: UIStackView!
    @IBOutlet weak var bottomStackViewSpacer: UIView!
    @IBOutlet weak var moreBtnView: UIView!
    @IBOutlet weak var commentStackView: UIStackView!
    @IBOutlet weak var likeStackView: UIStackView!
    
    @IBOutlet weak var richTextContentStack: UIStackView!
    @IBOutlet weak var externalUrlImageView: UIImageView!
    @IBOutlet weak var externalUrlDomainLabel: UILabel!
    @IBOutlet weak var externalUrlTitleLabel: UILabel!
    @IBOutlet weak var externalUrlDescriptionLabel: UILabel!
    @IBOutlet weak var audioTrack: OrbisTrackSlider!
    @IBOutlet weak var descriptionLabel: OrbisActiveLabel!
    @IBOutlet weak var viewMoreBtn: UIButton!
    
    @IBAction func playTapped(_ sender: Any) {
        guard viewModel.isPlayerReady else { return }
        tryPlayPause()
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        actionDelegate?.didTapMore(onCell: self, tappedView: moreBtnView, post: viewModel.model)
    }
    
    @IBAction func expandTextTapped(_ sender: Any) {
        var newPost = viewModel.model!
        newPost.isDescriptionExpanded = !newPost.isDescriptionExpanded
        actionDelegate?.didTapViewMore(onCell: self, post: newPost, maxLines: descriptionLabel.calculateMaxLines())
    }
    
    var viewModel: AudioPostCellViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    var playerConfig: SZAVPlayerConfig?
    var player: SZAVPlayer?
    
    weak var actionDelegate: PostCellActionDelegate?
    var onAudioStartPlaying: ((AudioPostTableViewCell?) -> Void)?
    var playerStatus: SZPlayerControllerEventType = .none
    
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
        audioLengthLabel.text = viewModel.audioLength
        updatePlayPauseIcon()
        updateProfilePic()
        fillSubPosterDetail()
        self.updateMediaPlayer()
        descriptionLabel.numberOfLines = viewModel.numberOfLines
        viewMoreBtn.isHidden = !(descriptionLabel.calculateMaxLines() > AppValues.postTextMaxLines)
        updateTextMoreBtnText()
    }
    
    private func updateTextMoreBtnText() {
        let title = (descriptionLabel.numberOfLines == 0) ? AppStrings.viewLess : AppStrings.viewMore
        viewMoreBtn.setTitle(title, for: .normal)
    }
    
    func updateMediaPlayer() {
        guard !viewModel.mediaUrl.isEmpty else { return }
        player?.reset()
        playerConfig = nil
        player = nil
        self.isUserInteractionEnabled = false
        self.showOrbisLoader()
        self.viewModel.fetchMediaUrl(forName: viewModel.mediaUrl) { [weak self] data, err in
            guard let self = self else { return }
            self.hideOrbisLoader()
            self.isUserInteractionEnabled = true
            guard let urlString = data as? String, let url = URL(string: urlString) else { return }
            self.setupAudioPlayer(withUrl: url)
        }
    }
    
    private func setupAudioPlayer(withUrl url: URL) {
        guard player == nil else {
            viewModel.audioDuration = player?.player?.currentItem?.asset.duration.seconds ?? 0
            viewModel.currentTime = player?.player?.currentItem?.currentTime().seconds ?? 0
            return
        }
        self.playerConfig = SZAVPlayerConfig(urlStr: url.absoluteString, uniqueID: nil)
        self.player = SZAVPlayer()
        self.player?.delegate = self
        self.player?.setupPlayer(config: self.playerConfig!)
        audioLengthLabel.text = viewModel.audioLength
//        self.viewModel.isPlayerReady = true
    }
    
    private func finishPlayerAudioInit() {
        self.viewModel.isPlayerReady = true
        self.viewModel.audioDuration = player?.totalTime ?? 0
        self.audioTrack.minimumValue = 0
        self.audioTrack.maximumValue = Float(player?.totalTime ?? 0)
        self.audioTrack.setValue(Float(player?.currentTime ?? 0), animated: false)
        
        audioLengthLabel.text = viewModel.audioLength
        self.updatePlayPauseIcon()
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
    
    func updatePlayPauseIcon() {
        audioPlayIconView.image = viewModel.playPauseIcon
    }
    
    func tryPlayPause() {
        guard let audioPlayer = player?.player else { return }
        if audioPlayer.rate == 0 {
            onAudioStartPlaying?(self)
            playPlayer()
        }
        else {
            pausePlayer()
        }
    }
    
    func playPlayer() {
        player?.play()
        viewModel.isPlaying = true
        updatePlayPauseIcon()
    }
    
    func pausePlayer() {
        player?.pause()
        viewModel.isPlaying = false
        updatePlayPauseIcon()
    }
}

extension AudioPostTableViewCell: SZAVPlayerDelegate {
    func avplayer(_ avplayer: SZAVPlayer, didReceived remoteCommand: SZAVPlayerRemoteCommand) -> Bool {
        return false
    }
    
    func avplayer(_ avplayer: SZAVPlayer, didChanged status: SZAVPlayerStatus) {
        switch status {
        case .readyToPlay:
            finishPlayerAudioInit()
            if playerStatus == .playing {
                player?.play()
            }
            return
        case .playEnd:
            self.player?.reset()
            viewModel.isPlaying = false
            updatePlayPauseIcon()
        case .loadingFailed:
            debugPrint("Failed to load audio for url \(avplayer.currentURLStr ?? "") error: \(avplayer.playerItem?.error?.localizedDescription ?? "")")
        case .bufferEnd:
            finishPlayerAudioInit()
            viewModel.audioDuration = player?.totalTime ?? 0
            if playerStatus == .stalled {
                player?.play()
            }
            return
        case .playbackStalled:
            playerStatus = .stalled
        default:
            return
        }
    }
    
    func avplayer(_ avplayer: SZAVPlayer, refreshed currentTime: Float64, loadedTime: Float64, totalTime: Float64) {
        viewModel.currentTime = currentTime
        audioLengthLabel.text = viewModel.audioLength
        audioTrack.setValue(Float(currentTime), animated: true)
    }
}

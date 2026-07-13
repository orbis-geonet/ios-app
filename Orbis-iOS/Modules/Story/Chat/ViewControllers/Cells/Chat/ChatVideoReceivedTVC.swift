//
//  ChatVideoReceivedTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/07/2021.
//

import UIKit
import AVKit

class ChatVideoCell: UITableViewCell {
    var player: AVPlayer?
    var playerVC: AVPlayerViewController?
    var playerObserver: NSKeyValueObservation?
}

class ChatVideoReceivedTVC: ChatVideoCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var onVideoStartedPlaying: ((ChatVideoCell?) -> Void)?
    
    var viewModel: ChatMessageViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerVC?.player?.pause()
    }
    
    deinit {
        playerObserver?.invalidate()
        playerObserver = nil
        player?.currentItem?.asset.cancelLoading()
        player?.cancelPendingPrerolls()
        playerVC?.view.removeFromSuperview()
        playerVC?.player = nil
        player?.replaceCurrentItem(with: nil)
        removeAllSubViews()
    }
    
    func updateViewContent() {
        dayLabel.isHidden = !viewModel.shouldShowDay
        dayLabel.text = viewModel.dateString
        timeLabel.text = viewModel.timeString
        removeAllSubViews()
        addPlayer()
    }

    private func removeAllSubViews() {
        videoContainerView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        videoContainerView.layer.sublayers?.forEach({ (layer) in
            if layer.isKind(of: AVPlayerLayer.self) {
                layer.removeFromSuperlayer()
            }
        })
    }

    private func addPlayer() {
        var urlStr = ""
        if viewModel.isPendingMessage {
            urlStr = viewModel.pendingVideo
            finalizeVideoSetup(withUrl: urlStr)
        }
        else {
            urlStr = viewModel.mediaUrl
            self.isUserInteractionEnabled = false
            self.showOrbisLoader()
            viewModel.fetchMediaUrl(forName: urlStr) { [weak self] data, err in
                guard let self = self else { return }
                self.hideOrbisLoader()
                self.isUserInteractionEnabled = true
                guard let urlString = data as? String else { return }
                self.finalizeVideoSetup(withUrl: urlString)
            }
        }
    }
    
    private func finalizeVideoSetup(withUrl urlStr: String) {
        if let url = URL(string: urlStr) {
            player = AVPlayer(url: url)
            playerVC = AVPlayerViewController()
            playerVC?.player = player!
            playerVC?.videoGravity = .resizeAspect
            playerVC?.view.frame.size.height = videoContainerView.frame.size.height
            playerVC?.view.frame.size.width = videoContainerView.frame.size.width
            self.playerObserver?.invalidate()
            self.playerObserver = nil
            self.playerObserver = player?.observe(\.rate, options: NSKeyValueObservingOptions.new, changeHandler: { player, changes in
                if player.rate > 0 {
                    self.onVideoStartedPlaying?(self)
                }
            })
            videoContainerView.addSubview(playerVC!.view)
        }
        else {
            let text = AppErrorStrings.couldNotLoadVideo
            let label = UILabel()
            label.font = UIFont(name: "Montserrat-Regular", size: CGFloat(10).relativeToIphone8Width())
            label.textColor = UIColor(named: AppColors.appWarmGray2.rawValue)
            label.text = text
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            videoContainerView.addSubview(label)
            let constantVal = CGFloat(10).relativeToIphone8Width()
            label.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor, constant: constantVal).isActive = true
            label.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor, constant: constantVal).isActive = true
            label.centerYAnchor.constraint(equalTo: videoContainerView.centerYAnchor).isActive = true
        }
    }
}

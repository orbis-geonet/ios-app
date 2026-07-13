//
//  IGPlayerView.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 14/07/18.
//  Copyright © 2018 DrawRect. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

struct VideoResource {
    let filePath: String
}

enum PlayerStatus {
    case unknown
    case playing
    case failed
    case paused
    case readyToPlay
}

//Move Implementation on ViewController or cell which ever the UIElement
//CALL BACK
protocol IGPlayerObserver: AnyObject {
    func didStartPlaying()
    func didCompletePlay()
    func didTrack(progress: Float)
    func didFailed(withError error: String, for url: URL?)
}

protocol PlayerControls: AnyObject {
    func play(with resource: VideoResource)
    func play()
    func pause()
    func stop()
    var playerStatus: PlayerStatus { get }
}

class IGPlayerView: UIView {
    
    //MARK: - Private Vars
    private var timeObserverToken: AnyObject?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem? = nil {
        willSet {
            // Remove any previous KVO observer.
            guard let playerItemStatusObserver = playerItemStatusObserver else { return }
            playerItemStatusObserver.invalidate()
        }
        didSet {
            player?.replaceCurrentItem(with: playerItem)
            playerItemStatusObserver = playerItem?.observe(\AVPlayerItem.status, options: [.new, .initial], changeHandler: { [weak self] (item, _) in
                guard let strongSelf = self else { return }
                if item.status == .failed {
                    strongSelf.activityIndicator.stopAnimating()
                    if let item = strongSelf.player?.currentItem, let error = item.error, let url = item.asset as? AVURLAsset {
                        strongSelf.playerObserverDelegate?.didFailed(withError: error.localizedDescription, for: url.url)
                    } else {
                        strongSelf.playerObserverDelegate?.didFailed(withError: "Unknown error", for: nil)
                    }
                }
            })
        }
    }
    
    //MARK: - iVars
    var player: AVPlayer? {
        willSet {
            // Remove any previous KVO observer.
            guard let playerTimeControlStatusObserver = playerTimeControlStatusObserver else { return }
            playerTimeControlStatusObserver.invalidate()
        }
        didSet {
            playerTimeControlStatusObserver = player?.observe(\AVPlayer.timeControlStatus, options: [.new, .initial], changeHandler: { [weak self] (player, _) in
                guard let strongSelf = self else { return }
                if player.timeControlStatus == .playing {
                    //Started Playing
                    strongSelf.activityIndicator.stopAnimating()
                    strongSelf.playerObserverDelegate?.didStartPlaying()
                } else if player.timeControlStatus == .paused {
                    // player paused
                } else {
                    //
                }
            })
        }
    }
    var error: Error? {
        return player?.currentItem?.error
    }
    var activityIndicator: UIActivityIndicatorView!
    
    var currentItem: AVPlayerItem? {
        return player?.currentItem
    }
    var currentTime: Float {
        return Float(self.player?.currentTime().value ?? 0)
    }
    var hasProgressorBeenInitialized = false
    
    //MARK: - Public Vars
    public weak var playerObserverDelegate: IGPlayerObserver?
    
    //MARK:- Init methods
    override init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: frame)
        setupActivityIndicator()
    }
    required init?(coder aDecoder: NSCoder) {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        super.init(coder: aDecoder)
        setupActivityIndicator()
    }
    override func layoutSubviews() {
        playerLayer?.frame = self.bounds
    }
    deinit {
        if let existingPlayer = player, existingPlayer.observationInfo != nil {
            removeObservers()
        }
    }
    
    // MARK: - Internal methods
    func setupActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        //backgroundColor = UIColor.rgb(from: 0xEDF0F1)
        backgroundColor = .black
        self.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.igCenterXAnchor.constraint(equalTo: self.igCenterXAnchor),
            activityIndicator.igCenterYAnchor.constraint(equalTo: self.igCenterYAnchor)
            ])
    }
    func startAnimating() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    func stopAnimating() {
        activityIndicator.startAnimating()
    }
    func removeObservers() {
        cleanUpPlayerPeriodicTimeObserver()
    }
    func cleanUpPlayerPeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    func setupPlayerPeriodicTimeObserver() {
        // Only add the time observer if one hasn't been created yet.
        guard timeObserverToken == nil else { return }
        
        // Use a weak self variable to avoid a retain cycle in the block.
        timeObserverToken =
            player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: DispatchQueue.main) {
                [weak self] time in
                let timeString = String(format: "%02.2f", CMTimeGetSeconds(time))
                if let currentItem = self?.player?.currentItem {
                    let totalTimeString =  String(format: "%02.2f", CMTimeGetSeconds(currentItem.asset.duration))
                    if timeString == totalTimeString {
                        self?.playerObserverDelegate?.didCompletePlay()
                    }
                }
                if let time = Float(timeString) {
                    self?.playerObserverDelegate?.didTrack(progress: time)
                }
            } as AnyObject
    }
}

// MARK: - Protocol | PlayerControls
extension IGPlayerView: PlayerControls {
    func fetchMediaUrl(forName name: String, completion: @escaping responseBlock) {
        guard name.isNotUrlLink else {
            completion(name, nil)
            return
        }
        let ref = name.getFirebaseFileStorageReference(storage: .postVideo)
        if let url = OrbisVideoCacheManager.shared.getUrl(forUrl: ref.fullPath) {
            completion(url, nil)
            return
        }
        else {
            ref.downloadURL {  url, err in
                if let videoUrl = url {
                    OrbisVideoCacheManager.shared.addUrl(forUrl: ref.fullPath, url: videoUrl.absoluteString)
                    completion(videoUrl.absoluteString, nil)
                    return
                }
                else {
                    completion(nil, err ?? ResponseError.invalidData)
                    return
                }
            }
        }
    }
    
    func play(with resource: VideoResource) {
        hasProgressorBeenInitialized = true
        fetchMediaUrl(forName: resource.filePath) { [weak self] data, err in
            guard let urlString = data as? String else { return }
            debugPrint("Player url has been fetched...")
            self?.performPlayVideo(source: urlString)
//            UIUtil.showGlobalToast(message: "Playing video with google cloud signed url")
//            self?.performPlayVideo(source: "https://storage.googleapis.com/orbis-v2.appspot.com/posts/videos/CAB28E0A-3A66-4194-BEED-C5338A2BFA98.mp4?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=firebase-adminsdk-jtef9%40orbis-v2.iam.gserviceaccount.com%2F20210913%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20210913T103523Z&X-Goog-Expires=36000&X-Goog-SignedHeaders=host&X-Goog-Signature=6ba4c5a363f9296875dde2d21d28561621b7f503dd11aeceeb79c122bc951448f790460e2a54320e6f532f236d033b8992e294fc6ef4158a0a613fc21c55674d71f86a48e8b333ba146b06bc33b1b5ac5ce0d90276d5f1d463b3f5511771eeb5834629dc716e053e2491ffd0385cdabb7f8bc1cbcc3cca3d44417d213cb745ca4ad230ae926e80fd1ddd71c1b429d5ab80167cd62c1b57d0d6ea281ef925ca43da4aa6a0402b191ba09a70078ffde94162eb37cbceee81c0d991e68449e52db0f6b81ece2acbd55ba5a85227e20b322e559dc5a9339fe612e58c9bb590474d46ae926ba8e72f27a1a8d4f429cd37f9ecebae2cd9733ceb50545bc0b8d5499d45")
        }
    }
    
    private func performPlayVideo(source: String) {
        guard let url = URL(string: source) else {fatalError("Unable to form URL from resource")}
        if let existingPlayer = player {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.player = existingPlayer
            }
        } else {
            guard hasProgressorBeenInitialized else { return }
            let asset = AVAsset(url: url)
            playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)
            playerLayer = AVPlayerLayer(player: player)
            setupPlayerPeriodicTimeObserver()
            if let pLayer = playerLayer {
                pLayer.videoGravity = .resizeAspect
                pLayer.frame = self.bounds
                self.layer.addSublayer(pLayer)
            }
        }
        startAnimating()
        player?.play()
    }
    func play() {
        //We have used this for long press gesture
        hasProgressorBeenInitialized = true
        if let existingPlayer = player {
            existingPlayer.play()
        }
    }
    func pause() {
        if let existingPlayer = player {
            existingPlayer.pause()
        }
    }
    func stop() {
        if let existingPlayer = player {
            hasProgressorBeenInitialized = false
            DispatchQueue.main.async {[weak self] in
                guard let strongSelf = self else { return }
                existingPlayer.pause()
                
                //Remove observer if observer presents before setting player to nil
                if existingPlayer.observationInfo != nil {
                    strongSelf.removeObservers()
                }
                strongSelf.playerItem = nil
                strongSelf.player = nil
                strongSelf.playerLayer?.removeFromSuperlayer()
            }
            //player got deallocated
        } else {
            //player was already deallocated
        }
    }
    var playerStatus: PlayerStatus {
        if let p = player {
            switch p.status {
            case .unknown: return .unknown
            case .readyToPlay: return .readyToPlay
            case .failed: return .failed
            @unknown default:
                return .unknown
            }
        }
        return .unknown
    }
}

//
//  OrbisStoryVideoSnapView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 15/04/2021.
//

import Foundation
import UIKit

class OrbisStoryVideoSnapView: UIView {
    
    var videoLayer: IGPlayerView!
    var postDescriptionLabel: UILabel!
    
    let mimeType: OrbisPostType!
    public weak var playerObserverDelegate: IGPlayerObserver?

    
    //MARK: - Overriden functions
    init(mimeType: OrbisPostType, playerObserverDelegate: IGPlayerObserver?) {
        self.mimeType = mimeType
        self.playerObserverDelegate = playerObserverDelegate
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        loadUIElements()
        installLayoutConstraints()
    }
    
    //MARK: - Private functions
    private func loadUIElements(){
        backgroundColor = .black
        initializeVideoView()
        initializeDescriptionLabel()
        addSubview(videoLayer)
        addSubview(postDescriptionLabel)
        self.bringSubviewToFront(postDescriptionLabel)
    }
    
    private func initializeVideoView() {
        let videoView = IGPlayerView()
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.playerObserverDelegate = playerObserverDelegate
        self.videoLayer = videoView
    }
    
    private func initializeDescriptionLabel() {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        lbl.textColor = .white
        lbl.font = UIFont(name: "Roboto-Regular", size: CGFloat(16).relativeToIphone8Width())!
        lbl.textAlignment = .center
        self.postDescriptionLabel = lbl
    }
    
    private func installLayoutConstraints(){
        NSLayoutConstraint.activate([
            videoLayer.igLeftAnchor.constraint(equalTo: self.igLeftAnchor),
            videoLayer.igTopAnchor.constraint(equalTo: self.igTopAnchor),
            self.igRightAnchor.constraint(equalTo: videoLayer.igRightAnchor),
            self.bottomAnchor.constraint(equalTo: videoLayer.igBottomAnchor)
            ])
        NSLayoutConstraint.activate([
            postDescriptionLabel.igLeftAnchor.constraint(equalTo: self.igLeftAnchor, constant: 15.toCGFloat.relativeToIphone8Width()),
            self.igRightAnchor.constraint(equalTo: postDescriptionLabel.igRightAnchor, constant: 15.toCGFloat.relativeToIphone8Width()),
            postDescriptionLabel.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 0.7),
            postDescriptionLabel.igCenterYAnchor.constraint(equalTo: self.igCenterYAnchor)
            ])
    }
}

//
//  OrbisStoryPreviewHeaderView.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 06/09/17.
//  Copyright © 2017 DrawRect. All rights reserved.
//

import UIKit

protocol StoryPreviewHeaderProtocol:AnyObject {
    func didTapCloseButton()
    func groupTapped()
}

fileprivate let maxSnaps = 30

//Identifiers
public let progressIndicatorViewTag = 88
public let progressViewTag = 99

final class OrbisStoryPreviewHeaderView: UIView {
    
    //MARK: - iVars
    public weak var delegate:StoryPreviewHeaderProtocol?
    fileprivate var snapsPerStory: Int = 0
    public var story:OrbisStory? {
        didSet {
            snapsPerStory  = (story?.snapsCount)! < maxSnaps ? (story?.snapsCount)! : maxSnaps
        }
    }
    fileprivate var progressView: UIView?
    let detailView: StoryHeaderView = {
        let view = StoryHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    public var getProgressView: UIView {
        if let progressView = self.progressView {
            return progressView
        }
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        self.progressView = v
        self.addSubview(self.getProgressView)
        return v
    }
    
    //MARK: - Overriden functions
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        applyShadowOffset()
        loadUIElements()
        installLayoutConstraints()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - Private functions
    private func loadUIElements(){
        backgroundColor = .clear
        addSubview(getProgressView)
        addSubview(detailView)
        detailView.onGroupTapped = {
            [weak self] in
            self?.delegate?.groupTapped()
        }
    }
    private func installLayoutConstraints(){
        //Setting constraints for progressView
        let pv = getProgressView
        NSLayoutConstraint.activate([
            pv.igLeftAnchor.constraint(equalTo: self.igLeftAnchor, constant: 7.toCGFloat.relativeToIphone8Width()),
            pv.igTopAnchor.constraint(equalTo: self.igTopAnchor, constant: 8.toCGFloat.relativeToIphone8Width()),
            self.igRightAnchor.constraint(equalTo: pv.igRightAnchor, constant: 7.toCGFloat.relativeToIphone8Width()),
            pv.heightAnchor.constraint(equalToConstant: 10.toCGFloat.relativeToIphone8Width())
            ])
//
//        //Setting constraints for snapperImageView
//        NSLayoutConstraint.activate([
//            snaperImageView.widthAnchor.constraint(equalToConstant: 40),
//            snaperImageView.heightAnchor.constraint(equalToConstant: 40),
//            snaperImageView.igLeftAnchor.constraint(equalTo: self.igLeftAnchor, constant: 10),
//            snaperImageView.igCenterYAnchor.constraint(equalTo: self.igCenterYAnchor),
//            detailView.igLeftAnchor.constraint(equalTo: snaperImageView.igRightAnchor, constant: 10)
//            ])
//        layoutIfNeeded() //To make snaperImageView round. Adding this to somewhere else will create constraint warnings.
        
        //Setting constraints for detailView
        NSLayoutConstraint.activate([
            detailView.igLeftAnchor.constraint(equalTo: self.igLeftAnchor, constant: 0),
            detailView.igTopAnchor.constraint(equalTo: pv.bottomAnchor, constant: 10.toCGFloat.relativeToIphone8Width()),
            detailView.igRightAnchor.constraint(equalTo: self.igRightAnchor, constant: 0),
            detailView.igBottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            ])
        
//        //Setting constraints for closeButton
//        NSLayoutConstraint.activate([
//            closeButton.igLeftAnchor.constraint(equalTo: detailView.igRightAnchor, constant: 10),
//            closeButton.igCenterYAnchor.constraint(equalTo: self.igCenterYAnchor),
//            closeButton.igRightAnchor.constraint(equalTo: self.igRightAnchor),
//            closeButton.widthAnchor.constraint(equalToConstant: 60),
//            closeButton.heightAnchor.constraint(equalToConstant: 80)
//            ])
    }
    private func applyShadowOffset() {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
    }
    private func applyProperties<T: UIView>(_ view: T, with tag: Int? = nil, alpha: CGFloat = 1.0) -> T {
        view.layer.cornerRadius = 1
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.white.withAlphaComponent(alpha)
        if let tagValue = tag {
            view.tag = tagValue
        }
        return view
    }
    
    //MARK: - Selectors
    @objc func didTapClose(_ sender: UIButton) {
        delegate?.didTapCloseButton()
    }
    
    //MARK: - Public functions
    public func clearTheProgressorSubviews() {
        getProgressView.subviews.forEach { v in
            v.subviews.forEach{v in (v as! IGSnapProgressView).stop()}
            v.removeFromSuperview()
        }
    }
    public func clearAllProgressors() {
        clearTheProgressorSubviews()
        getProgressView.removeFromSuperview()
        self.progressView = nil
    }
    public func clearSnapProgressor(at index:Int) {
        getProgressView.subviews[index].removeFromSuperview()
    }
    public func createSnapProgressors(){
        print("Progressor count: \(getProgressView.subviews.count)")
        let padding: CGFloat = 8.toCGFloat.relativeToIphone8Width() //GUI-Padding
        let height: CGFloat = 3.toCGFloat.relativeToIphone8Width()
        var pvIndicatorArray: [IGSnapProgressIndicatorView] = []
        var pvArray: [IGSnapProgressView] = []
        
        // Adding all ProgressView Indicator and ProgressView to seperate arrays
        for i in 0..<snapsPerStory{
            let pvIndicator = IGSnapProgressIndicatorView()
            pvIndicator.translatesAutoresizingMaskIntoConstraints = false
            getProgressView.addSubview(applyProperties(pvIndicator, with: i+progressIndicatorViewTag, alpha:0.2))
            pvIndicatorArray.append(pvIndicator)
            
            let pv = IGSnapProgressView()
            pv.translatesAutoresizingMaskIntoConstraints = false
            pvIndicator.addSubview(applyProperties(pv))
            pvArray.append(pv)
        }
        // Setting Constraints for all progressView indicators
        for index in 0..<pvIndicatorArray.count {
            let pvIndicator = pvIndicatorArray[index]
            if index == 0 {
                pvIndicator.leftConstraiant = pvIndicator.igLeftAnchor.constraint(equalTo: self.getProgressView.igLeftAnchor, constant: padding)
                NSLayoutConstraint.activate([
                    pvIndicator.leftConstraiant!,
                    pvIndicator.igCenterYAnchor.constraint(equalTo: self.getProgressView.igCenterYAnchor),
                    pvIndicator.heightAnchor.constraint(equalToConstant: height)
                    ])
                if pvIndicatorArray.count == 1 {
                    pvIndicator.rightConstraiant = self.getProgressView.igRightAnchor.constraint(equalTo: pvIndicator.igRightAnchor, constant: padding)
                    pvIndicator.rightConstraiant!.isActive = true
                }
            }else {
                let prePVIndicator = pvIndicatorArray[index-1]
                pvIndicator.igWidthConstraint = pvIndicator.widthAnchor.constraint(equalTo: prePVIndicator.widthAnchor, multiplier: 1.0)
                pvIndicator.leftConstraiant = pvIndicator.igLeftAnchor.constraint(equalTo: prePVIndicator.igRightAnchor, constant: padding)
                NSLayoutConstraint.activate([
                    pvIndicator.leftConstraiant!,
                    pvIndicator.igCenterYAnchor.constraint(equalTo: prePVIndicator.igCenterYAnchor),
                    pvIndicator.heightAnchor.constraint(equalToConstant: height),
                    pvIndicator.igWidthConstraint!
                    ])
                if index == pvIndicatorArray.count-1 {
                    pvIndicator.rightConstraiant = self.igRightAnchor.constraint(equalTo: pvIndicator.igRightAnchor, constant: padding)
                    pvIndicator.rightConstraiant!.isActive = true
                }
            }
        }
        // Setting Constraints for all progressViews
        for index in 0..<pvArray.count {
            let pv = pvArray[index]
            let pvIndicator = pvIndicatorArray[index]
            pv.igWidthConstraint = pv.widthAnchor.constraint(equalToConstant: 0)
            NSLayoutConstraint.activate([
                pv.igLeftAnchor.constraint(equalTo: pvIndicator.igLeftAnchor),
                pv.heightAnchor.constraint(equalTo: pvIndicator.heightAnchor),
                pv.igTopAnchor.constraint(equalTo: pvIndicator.igTopAnchor),
                pv.igWidthConstraint!
                ])
        }
        detailView.groupNameLabel.text = story?.group.name
    }
}

//
//  StoryFooterView.swift
//  InstagramStories
//
//  Created by Nikesh Shakya on 15/04/2021.
//  Copyright © 2021 DrawRect. All rights reserved.
//

import UIKit

class StoryFooterView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var userProPicContainerView: RoundedView!
    @IBOutlet weak var userFullNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var postDescriptionLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var postDescriptionStackView: UIStackView!
    @IBOutlet weak var readMoreBtn: UIButton!
    
    @IBOutlet weak var likeCountStackView: UIStackView!
    @IBOutlet weak var likeIconView: UIView!
    @IBOutlet weak var likeStackView: UIStackView!
    @IBOutlet weak var commentStackView: UIStackView!
    @IBOutlet weak var commentIconView: UIView!
    @IBOutlet weak var commentCountStackView: UIStackView!
    
    @IBAction func readMoreTapped(_ sender: Any) {
        hideDescriptionStack()
    }
    
    var onReadMoreTapped: (() -> Void)?
    var onUserTapped: (() -> Void)?
    var onLikeTapped: (() -> Void)?
    var onCommentTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("StoryFooterView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addViewActions()
    }
    
    func addViewActions() {
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(likeTapped(_:)))
        let likeCountTapGesture = UITapGestureRecognizer(target: self, action: #selector(likeCountTapped(_:)))
        
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(commentTapped(_:)))
        let commentCountTapGesture = UITapGestureRecognizer(target: self, action: #selector(commentCountTapped(_:)))
        
        let userProfileHeadTapGesture = UITapGestureRecognizer(target: self, action: #selector(userNamePicTapped(_:)))
        let userNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(userNamePicTapped(_:)))
        
        likeIconView.isUserInteractionEnabled = true
        likeIconView.addGestureRecognizer(likeTapGesture)
        likeCountStackView.isUserInteractionEnabled = true
        likeCountStackView.addGestureRecognizer(likeCountTapGesture)
        
        commentIconView.isUserInteractionEnabled = true
        commentIconView.addGestureRecognizer(commentTapGesture)
        commentCountStackView.isUserInteractionEnabled = true
        commentCountStackView.addGestureRecognizer(commentCountTapGesture)
        
        userFullNameLabel.isUserInteractionEnabled = true
        userFullNameLabel.addGestureRecognizer(userNameTapGesture)
        userProPicContainerView.isUserInteractionEnabled = true
        userProPicContainerView.addGestureRecognizer(userProfileHeadTapGesture)
    }
    
    @objc private func likeTapped(_ sender: UITapGestureRecognizer) {
        onLikeTapped?()
    }
    
    @objc private func likeCountTapped(_ sender: UITapGestureRecognizer) {
        onLikeTapped?()
    }
    
    @objc private func commentTapped(_ sender: UITapGestureRecognizer) {
        onCommentTapped?()
    }
    
    @objc private func commentCountTapped(_ sender: UITapGestureRecognizer) {
        onCommentTapped?()
    }
    
    @objc private func userNamePicTapped(_ sender: UITapGestureRecognizer) {
        onUserTapped?()
    }
    
    func resetDescriptionLabel() {
//        let linkFont = UIFont(name: "Roboto-Black", size: CGFloat(14).relativeToIphone8Width())!
//        postDescriptionLabel.setLessLinkWith(lessLink: "Read Less", attributes: [
//            .foregroundColor:UIColor(named: AppColors.appBlue.rawValue)!,
//            .font: linkFont
//        ], position: .left)
//        postDescriptionLabel.collapsedAttributedLink = NSAttributedString(string: "Read More", attributes: [
//            .foregroundColor:UIColor(named: AppColors.appBlue.rawValue)!,
//            .font: linkFont
//        ])
//        postDescriptionLabel.shouldCollapse = true
//        postDescriptionLabel.textReplacementType = .word
//        postDescriptionLabel.numberOfLines = 4
//        postDescriptionLabel.collapsed = true
//        postDescriptionLabel.layoutIfNeeded()
//        self.layoutIfNeeded()
        readMoreBtn.isHidden = true
    }
    
    private func hideDescriptionStack() {
        UIView.animate(withDuration: 0.2) {
            [weak self] in
            self?.postDescriptionStackView.isHidden = true
        } completion: { [weak self] (success) in
            self?.onReadMoreTapped?()
        }
    }
    
    func showDescriptionStack() {
        UIView.animate(withDuration: 0.2) {
            [weak self] in
            self?.postDescriptionStackView.isHidden = false
        } completion: { (success) in
        }
    }
    
    func updateReadMoreVisibility() {
        let lines = postDescriptionLabel.calculateMaxLines()
        readMoreBtn.isHidden = lines < 5
    }

}

//
//  StoryHeaderView.swift
//  InstagramStories
//
//  Created by Nikesh Shakya on 15/04/2021.
//  Copyright © 2021 DrawRect. All rights reserved.
//

import UIKit

class StoryHeaderView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var groupProPicContainerView: RoundedView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var datePostedLabel: UILabel!
    @IBOutlet weak var postLocationLabel: UILabel!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var locationStackView: UIStackView!
    
    
    var onGroupTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("StoryHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addViewActions()
    }

    func addViewActions() {
        
        let groupProfileHeadTapGesture = UITapGestureRecognizer(target: self, action: #selector(groupNamePicTapped(_:)))
        let groupNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(groupNamePicTapped(_:)))
        
        groupNameLabel.isUserInteractionEnabled = true
        groupNameLabel.addGestureRecognizer(groupNameTapGesture)
        groupProPicContainerView.isUserInteractionEnabled = true
        groupProPicContainerView.addGestureRecognizer(groupProfileHeadTapGesture)
    }
    
    @objc private func groupNamePicTapped(_ sender: UITapGestureRecognizer) {
        onGroupTapped?()
    }
}

//
//  StoryItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit
import SDWebImage


protocol StoryItemTapDelegate: AnyObject {
    func didTapStoryCell(cell: StoryItemCollectionViewCell)
}

class StoryItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var storyContainerView: RoundedView!
    @IBOutlet weak var userProPicView: UIImageView!
    
    weak var tapDelegate: StoryItemTapDelegate?
    
    var viewModel: StoryItemViewModel! {
        didSet {
            updateContent()
        }
    }

    @IBAction func storyTapped(_ sender: Any) {
        tapDelegate?.didTapStoryCell(cell: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateContent() {
        storyContainerView.borderColor = viewModel.groupBaseColor
        storyContainerView.borderDashGap = viewModel.borderDashGap
        storyContainerView.borderDashWidth = viewModel.borderDashWidth
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.propicLink.isEmpty else {
            userProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        userProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .groupPictures, sizeModifier: .twoHundred)
    }
    
}

//
//  EventUserItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import UIKit
import SDWebImage


class EventUserItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var proPicContainerView: RoundedView!
    
    var viewModel: EventUserItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateViewContent() {
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.propicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
}

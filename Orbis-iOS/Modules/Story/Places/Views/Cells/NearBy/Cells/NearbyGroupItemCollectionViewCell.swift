//
//  NearbyGroupItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import UIKit
import SDWebImage


class NearbyGroupItemCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicImageView: UIImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var spacer: UIView!
    @IBOutlet weak var placeIndicatorView: RoundedView!
    @IBOutlet weak var placeStackView: UIStackView!
    
    var viewModel: NearbyGroupCellItemViewModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateViewContent(atIndex index: Int, count: Int) {
        placeStackView.alignment = (index == 0) ? .leading : .center
        placeNameLabel.isHidden = (index == 0) ? false : true
        spacer.isHidden = (index == count - 1)
        placeNameLabel.text = viewModel.name
        proPicContainerView.borderColor = viewModel.baseColor
        placeIndicatorView.backgroundColor = viewModel.baseColor
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.propicLink.isEmpty else {
            proPicImageView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        proPicImageView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .groupPictures, sizeModifier: .fourHundred)
    }

}

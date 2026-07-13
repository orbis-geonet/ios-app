//
//  GroupListItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import UIKit
import SDWebImage


class GroupListItemTableViewCell: UITableViewCell {
    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusIndicatorIconView: UIImageView!
    var shouldHideStatusIcon = false
    
    var viewModel: GroupItemViewModel! {
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
    
    func updateViewContent() {
        proPicContainerView.borderColor = viewModel.baseColor
        nameLabel.text = viewModel.name
        statusIndicatorIconView.image = viewModel.indicatorImage
        statusIndicatorIconView.isHidden = shouldHideStatusIcon
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        proPicView.image = placeholderImage
        guard !viewModel.propicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .groupPictures, sizeModifier: .fourHundred)
    }

}

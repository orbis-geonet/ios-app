//
//  SearchedGroupItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import UIKit


class SearchedGroupItemTableViewCell: UITableViewCell {
    @IBOutlet weak var groupPicContainerView: RoundedView!
    @IBOutlet weak var groupPicView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    
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
        groupPicContainerView.borderColor = viewModel.baseColor
        groupNameLabel.text = viewModel.name
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.propicLink.isEmpty else {
            groupPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        groupPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .groupPictures, sizeModifier: .fourHundred)
    }

}

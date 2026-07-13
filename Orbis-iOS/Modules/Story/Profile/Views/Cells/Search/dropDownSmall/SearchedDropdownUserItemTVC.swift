//
//  SearchedDropdownUserItemTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import UIKit
import SDWebImage


class SearchedDropdownUserItemTVC: UITableViewCell {

    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var viewModel: SearchDropDownItemViewModel! {
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
        nameLabel.text = viewModel.name
        proPicContainerView.borderColor = viewModel.baseColor
        proPicContainerView.borderWidth = 3.toCGFloat.relativeToIphone8Width()
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.propicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: (viewModel.userModel == nil) ? .groupPictures : .profilePictures, sizeModifier: .fourHundred)
    }

}

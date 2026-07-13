//
//  UserSearchItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import UIKit
import SDWebImage


class UserSearchItemTableViewCell: UITableViewCell {

    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var adminIndicatorIconView: UIImageView!
    @IBOutlet weak var userBannedIndicatorView: UIImageView!
    
    var viewModel: UserItemViewModel! {
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
        updateProfilePic()
        setAdminIndicatorVisibility()
        setBannedIconVisibility()
    }
    
    func setAdminIndicatorVisibility(visible: Bool = false) {
        adminIndicatorIconView.isHidden = !visible
    }
    
    func setBannedIconVisibility(visible: Bool = false) {
        userBannedIndicatorView.isHidden = !visible
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

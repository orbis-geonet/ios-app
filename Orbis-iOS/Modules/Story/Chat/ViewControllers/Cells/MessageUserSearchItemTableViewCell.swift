//
//  MessageUserSearchItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import UIKit
import SDWebImage

class MessageUserSearchItemTableViewCell: UITableViewCell {
    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var viewModel: MessageSearchedUserViewModel! {
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
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.proPicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.proPicLink
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
}

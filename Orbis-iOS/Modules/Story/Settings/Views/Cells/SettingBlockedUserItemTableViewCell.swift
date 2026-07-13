//
//  SettingBlockedUserItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/11/2021.
//

import UIKit

class SettingBlockedUserItemTableViewCell: UITableViewCell {

    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var unblockLabel: UILabel!
    @IBOutlet weak var unblockBtn: UIButton!
    @IBAction func unblockTapped(_ sender: Any) {
        onUnblockTapped?(viewModel.model)
    }
    
    var viewModel: UserItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    var onUnblockTapped: ((OrbisUser) -> Void?)?
    
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
        guard !viewModel.propicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }


}

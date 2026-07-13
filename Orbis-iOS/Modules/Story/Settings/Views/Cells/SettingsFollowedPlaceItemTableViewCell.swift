//
//  SettingsFollowedPlaceItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit

class SettingsFollowedPlaceItemTableViewCell: UITableViewCell {
    @IBOutlet weak var placePicContainerView: RoundedView!
    @IBOutlet weak var placePicView: UIImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    
    
    @IBAction func unfollowTapped(_ sender: Any) {
        self.onUnfollowTapped?(viewModel.model)
    }
    
    var viewModel: CheckinPlaceItemViewModel! {
        didSet {
            updateCellViewContent()
        }
    }
    var onUnfollowTapped: ((OrbisPlace) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateCellViewContent() {
        placeNameLabel.text = viewModel.placeName
        placePicContainerView.borderWidth = 0
        placePicContainerView.borderColor = .clear
        placePicView.image = viewModel.placeTypeImage
    }

}

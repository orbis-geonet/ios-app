//
//  SearchedCheckinItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import UIKit

class SearchedCheckinItemTableViewCell: UITableViewCell {
    @IBOutlet weak var checkinImageContainerView: RoundedView!
    @IBOutlet weak var checkinImageView: UIImageView!
    
    @IBOutlet weak var checkinNameLabel: UILabel!
    
    var viewModel: CheckinPlaceItemViewModel! {
        didSet {
            updateCellViewContent()
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
    
    func updateCellViewContent() {
        checkinNameLabel.text = viewModel.placeName
        checkinImageContainerView.borderWidth = 3.toCGFloat.relativeToIphone8Width()
        checkinImageContainerView.borderColor = viewModel.placeTypeBorderColor
        checkinImageView.image = viewModel.placeTypeImage
    }

}

class SearchedCheckinItemTableViewCellWithImage: UITableViewCell {
    @IBOutlet weak var checkinImageContainerView: RoundedView!
    @IBOutlet weak var checkinImageView: UIImageView!
    
    @IBOutlet weak var checkinNameLabel: UILabel!
    
    var discardGroupImage: Bool = false
    var viewModel: CheckinPlaceItemViewModel! {
        didSet {
            updateCellViewContent()
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
    
    func updateCellViewContent() {
        checkinNameLabel.text = viewModel.placeName
        checkinImageContainerView.borderWidth = 3.toCGFloat.relativeToIphone8Width()
        checkinImageContainerView.borderColor = viewModel.borderColor
        let placeHolder = viewModel.placeTypeImage
        if discardGroupImage {
            guard !viewModel.placeProPicLink.isEmpty else {
                checkinImageView.image = placeHolder
                return
            }
            let proPicLink = viewModel.placeProPicLink
            
            checkinImageView.setSDWebImage(urlString: proPicLink, placeholderImage: placeHolder, storageDirectory: .placePictures, sizeModifier: .fourHundred)
        }
        else {
            guard !viewModel.placeDominantGroupImageLink.isEmpty else {
                checkinImageView.image = placeHolder
                return
            }
            let proPicLink = viewModel.placeDominantGroupImageLink
            
            checkinImageView.setSDWebImage(urlString: proPicLink, placeholderImage: placeHolder, storageDirectory: .groupPictures, sizeModifier: .fourHundred)
        }
    }

}

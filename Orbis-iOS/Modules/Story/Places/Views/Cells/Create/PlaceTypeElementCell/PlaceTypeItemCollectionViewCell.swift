//
//  PlaceTypeItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import UIKit

class PlaceTypeItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var itemContainerView: RoundedView!
    @IBOutlet weak var itemImageView: UIImageView!
    
    var itemImage: UIImage? {
        didSet {
            itemImageView.image = itemImage
        }
    }
    
    func updateItemSelection(isSelected: Bool) {
        itemImageView.tintColor = isSelected ? UIColor(named: AppColors.appBlack.rawValue) : UIColor(named: AppColors.appWarmGray2.rawValue)
        itemContainerView.borderWidth = isSelected ? 0 : 1
        itemContainerView.shadowOpacity = isSelected ? 0.16 : 0
    }
}

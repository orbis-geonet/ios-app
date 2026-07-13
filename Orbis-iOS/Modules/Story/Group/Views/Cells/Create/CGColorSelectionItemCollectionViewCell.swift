//
//  CGColorSelectionItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import UIKit

class CGColorSelectionItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var outerContainerView: RoundedView!
    @IBOutlet weak var innerContainerView: RoundedView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateContent(withColor color: UIColor, isSelected: Bool) {
        outerContainerView.shadowColor = color
        innerContainerView.backgroundColor = color
        innerContainerView.borderWidth = isSelected ? 3.toCGFloat.relativeToIphone8Width() : 0
        outerContainerView.shadowOpacity = isSelected ? 0.4 : 0
        outerContainerView.layoutIfNeeded()
        innerContainerView.layoutIfNeeded()
    }
    
}

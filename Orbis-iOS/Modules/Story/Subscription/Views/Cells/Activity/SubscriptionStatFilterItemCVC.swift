//
//  SubscriptionStatFilterItemCVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 05/01/2023.
//

import UIKit

class SubscriptionStatFilterItemCVC: UICollectionViewCell {
    static let identifier = "graphFilterItemCell"
    static let nibName = "SubscriptionStatFilterItemCVC"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentContainer: RoundedView!
    
    var isActive = false {
        didSet {
            updateContentUI()
        }
    }
    var name: String = "" {
        didSet {
            updateContentUI()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    private func updateContentUI() {
        nameLabel.text = name
        nameLabel.font = isActive ? UIFont(name: "Roboto-Bold", size: CGFloat(12).relativeToIphone8Width())! : UIFont(name: "Roboto-Regular", size: CGFloat(12).relativeToIphone8Width())!
        nameLabel.textColor = isActive ? .white : UIColor(named: AppColors.appBlack.rawValue)
        contentContainer.borderWidth = isActive ? 0.toCGFloat : 1.toCGFloat
        contentContainer.backgroundColor = isActive ? UIColor(named: AppColors.appBlack.rawValue) : .white
    }
}

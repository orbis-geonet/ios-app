//
//  SettingsLanguageItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit

class SettingsLanguageItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var radioBtnContainerView: RoundedView!
    @IBOutlet weak var radioBtnSelectedView: RoundedView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateSelection(isSelected: Bool) {
        radioBtnContainerView.borderColor = isSelected ? UIColor(named: AppColors.appBlack.rawValue) : UIColor(named: AppColors.appWarmGray2.rawValue)
        radioBtnSelectedView.isHidden = !isSelected
    }

}

//
//  SettingsMyPurchaseItemTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 21/08/2023.
//

import UIKit

class SettingsMyPurchaseItemTVC: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionBtn: UIButton!
    
    @IBAction func actionBtnTapped(_ sender: Any) {
        onActionBtnTapped?(self)
    }
    
    var model: UserPurchaseModel! {
        didSet {
            updateCellComponents()
        }
    }
    
    var purchaseDescription: String {
        let name = model.name ?? ""
        return "\(name) - \(model.currency?.toCurrencySymbol ?? "")\(model.price?.rounded(toPlaces: 2).formattedWithSeparator(decimalSeparator: ",", groupingSeparator: ".") ?? "")"
    }
    
    var onActionBtnTapped: ((SettingsMyPurchaseItemTVC) -> Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    private func updateCellComponents() {
        nameLabel.text = model.groupName ?? ""
        descriptionLabel.text = purchaseDescription
        actionBtn.setTitle(AppStrings.Subscription.seeCodesText, for: .normal)
    }
}

//
//  PurchasedCodeItemTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 21/08/2023.
//

import UIKit

class PurchasedCodeItemTVC: UITableViewCell {
    static let nibName = "PurchasedCodeItemTVC"
    static let identifier = "purchasedCodeItemTVC"
    
    @IBOutlet weak var purchaseCodeLabel: UILabel!
    
    var code: String = "" {
        didSet {
            purchaseCodeLabel.text = code
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

}

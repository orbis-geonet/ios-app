//
//  DropDownOptionItemCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/08/2023.
//

import UIKit

class DropDownOptionItemCell: UITableViewCell {
    static let nibName = "DropDownOptionItemCell"
    static let identifier = "dropDownOptionItemCell"

    @IBOutlet weak var nameLabel: UILabel!
    
    var name: String = "" {
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
        nameLabel.text = name
    }
    
}

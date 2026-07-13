//
//  PlaceInfoTextTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/08/2023.
//

import UIKit

class PlaceInfoTextTVC: UITableViewCell {
    static let nibName = "PlaceInfoTextTVC"
    static let identifier = "placeInfoTextTVC"
    
    @IBOutlet weak var contentTextLabel: UILabel!
    @IBOutlet weak var copyIcon: UIImageView!
    @IBOutlet weak var contentStackView: UIStackView!
    
    var contentText: String! {
        didSet {
            contentTextLabel.text = contentText
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

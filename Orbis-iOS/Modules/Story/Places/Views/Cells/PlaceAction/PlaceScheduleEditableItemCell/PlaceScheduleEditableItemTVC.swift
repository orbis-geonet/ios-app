//
//  PlaceScheduleEditableItemTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/08/2023.
//

import UIKit

class PlaceScheduleEditableItemTVC: UITableViewCell {
    static let nibName = "PlaceScheduleEditableItemTVC"
    static let identifier = "placeScheduleEditableItemTVC"
    
    @IBOutlet weak var contentIdentifierTextLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var startTimeTfContainer: RoundedView!
    @IBOutlet weak var startTimeTextField: UITextField!
    @IBOutlet weak var timeSeparatorLabel: UILabel!
    @IBOutlet weak var endTimeTfContainer: RoundedView!
    @IBOutlet weak var endTimeTextField: UITextField!
    
    @IBAction func startTimeTfTapped(_ sender: Any) {
        onStartTimeTapped?(model)
    }
    @IBAction func endTimeTfTapped(_ sender: Any) {
        onEndTimeTapped?(model)
    }
    
    var model: OrbisPlaceWorkingHours! {
        didSet {
            contentIdentifierTextLabel.text = model.dayName
            startTimeTextField.text = model.startTime
            endTimeTextField.text = model.endTime
            
            startTimeTfContainer.borderColor = UIColor(named: AppColors.appBlack.rawValue)
            endTimeTfContainer.borderColor = UIColor(named: AppColors.appBlack.rawValue)
            
            if model.startTime.isEmpty && !model.endTime.isEmpty {
                startTimeTfContainer.borderColor = UIColor(named: AppColors.appRed.rawValue)
            }
            if model.endTime.isEmpty && !model.startTime.isEmpty {
                endTimeTfContainer.borderColor = UIColor(named: AppColors.appRed.rawValue)
            }
        }
    }
    var onStartTimeTapped: ((OrbisPlaceWorkingHours) -> Void)?
    var onEndTimeTapped: ((OrbisPlaceWorkingHours) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}

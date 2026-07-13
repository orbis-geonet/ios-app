//
//  CreateGroupAlertViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import UIKit

class CreateGroupAlertViewController: PopupViewController {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var understoodBtn: UIButton!
    
    
    @IBAction func understoodTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            [weak self] in
            self?.onUnderstoodTapped?()
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var onUnderstoodTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
    }

    override func updateStaticTexts() {
        messageLabel.text = AppStrings.Group.Create.createGroupAlertMessage
        understoodBtn.setTitle(AppStrings.understood, for: .normal)
    }
}

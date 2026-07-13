//
//  ForgotPasswordSuccessViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/04/2021.
//

import UIKit

class ForgotPasswordSuccessViewController: OrbisLocalizableViewController {

    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var understoodBtn: UIButton!
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func proceedTapped(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
        // Do any additional setup after loading the view.
    }

    override func updateStaticTexts() {
        headingLabel.text = AppStrings.Authentication.forgotPasswordSuccessTitle
        messageLabel.text = AppStrings.Authentication.forgotPasswordSuccessMessage
        understoodBtn.setTitle(AppStrings.understood + " !", for: .normal)
    }
}

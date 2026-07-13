//
//  ForgotPasswordViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/04/2021.
//

import UIKit
import SkyFloatingLabelTextField
import FirebaseAuth

class ForgotPasswordViewController: OrbisLocalizableViewController {

    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var sendBtn: UIButton!
    
    
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func submitTapped(_ sender: Any) {
        trySubmitPasswordResetLink()
    }
    
    var viewModel: ForgotPasswordViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ForgotPasswordViewModel()
        emailTextField.text = ""
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        headingLabel.text = AppStrings.Authentication.forgotPasswordTitle
        messageLabel.text = AppStrings.Authentication.forgotPasswordMessage
        sendBtn.setTitle(AppStrings.Authentication.send, for: .normal)
        emailTextField.setStaticText(text: AppStrings.Authentication.email)
    }

    private func showSuccessVC() {
        let forgotPasswordSuccessVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "forgotPasswordSuccessVC") as! ForgotPasswordSuccessViewController
        self.navigationController?.pushViewController(forgotPasswordSuccessVC, animated: true)
        
    }
    
    private func trySubmitPasswordResetLink() {
        guard let email = emailTextField.text else {
            self.handleError(error: ValidationErrors.emptyEmail)
            return
        }
        guard email.isValidEmail else {
            self.handleError(error: ValidationErrors.invalidEmail)
            return
        }
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.trySendEmailResetLink(forEmail: email) { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.showSuccessVC()
            }
            self?.hideOrbisLoader()
        }
    }
}

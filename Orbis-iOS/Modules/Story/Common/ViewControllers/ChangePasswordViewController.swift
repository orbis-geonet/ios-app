//
//  ChangePasswordViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 22/09/2021.
//

import UIKit

class ChangePasswordViewController: PopupViewController {
    
    @IBOutlet weak var contentView: RoundedView!
    @IBOutlet weak var contentTitleLabel: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var oldPasswordTextField: PasswordSkyFloatingTextField!
    @IBOutlet weak var oldPwdEyeIconView: UIImageView!
    @IBOutlet weak var newPasswordTextField: PasswordSkyFloatingTextField!
    @IBOutlet weak var newPwdEyeIconView: UIImageView!
    @IBOutlet weak var confirmPasswordTextField: PasswordSkyFloatingTextField!
    @IBOutlet weak var confirmPwdEyeIconView: UIImageView!
    
    var saveBtnTitle = AppStrings.save
    var contentTitle: String = ""
    
    var onSave: ((String, String) -> Void)?
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        trySave()
    }
    @IBAction func confirmPwdEyeTapped(_ sender: Any) {
        togglePasswordSecure(passwordTextField: confirmPasswordTextField, passwordSecureIconView: confirmPwdEyeIconView)
    }
    @IBAction func newPwdEyeTapped(_ sender: Any) {
        togglePasswordSecure(passwordTextField: newPasswordTextField, passwordSecureIconView: newPwdEyeIconView)
    }
    @IBAction func oldPwdEyeTapped(_ sender: Any) {
        togglePasswordSecure(passwordTextField: oldPasswordTextField, passwordSecureIconView: oldPwdEyeIconView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveBtn.setTitle(saveBtnTitle, for: .normal)
        contentTitleLabel.text = contentTitle
        oldPasswordTextField.text = ""
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
    }
    
    func togglePasswordSecure(passwordTextField: PasswordSkyFloatingTextField, passwordSecureIconView: UIImageView) {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        passwordSecureIconView.tintColor = passwordTextField.isSecureTextEntry ? UIColor(named: AppColors.appBlack.rawValue) : UIColor(named: AppColors.appPinkishGray.rawValue)
    }
    
    func trySave() {
        let oldPwd = oldPasswordTextField.text ?? ""
        let newPwd = newPasswordTextField.text ?? ""
        let confirmPwd = confirmPasswordTextField.text ?? ""
        if oldPwd.isEmpty {
            self.handleError(error: ValidationErrors.emptyPassword)
            return
        }
        else if newPwd.isEmpty {
            self.handleError(error: ValidationErrors.emptyNewPassword)
            return
        }
        else if newPwd != confirmPwd {
            self.handleError(error: ValidationErrors.passwordsDoNotMatch)
            return
        }
        else {
            self.dismiss(animated: true) {
                [weak self] in
                guard let self = self else { return }
                self.onSave?(oldPwd, newPwd)
            }
        }
        
    }
    

}

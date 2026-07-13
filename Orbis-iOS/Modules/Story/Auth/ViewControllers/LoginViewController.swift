//
//  LoginViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/04/2021.
//

import UIKit
import SkyFloatingLabelTextField
import FirebaseInstallations

class LoginViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var forgotPasswordBtn: UIButton!
    @IBOutlet weak var usernameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordTextField: PasswordSkyFloatingTextField!
    @IBOutlet weak var passwordSecureIconView: UIImageView!
    
    @IBAction func passwordHideUnhideTapped(_ sender: Any) {
        toggleIsSecured()
    }
    @IBAction func loginTapped(_ sender: Any) {
        tryLogin()
    }
    @IBAction func forgotPasswordTapped(_ sender: Any) {
        showforgotPasswordVC()
    }
    
    var viewModel: LoginViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
        Installations.installations().delete { (err) in
            if let error = err {
                debugPrint("Error in revoking fcm \(error.localizedDescription)")
            }
            else {
                Installations.installations().installationID { (val, err) in
                    if let error = err {
                        debugPrint("Error in revoking fcm \(error.localizedDescription)")
                    }
                }
            }
        }
        viewModel = LoginViewModel()
        configureTextFields()
    }
    
    override func updateStaticTexts() {
        loginBtn.setTitle(AppStrings.Authentication.login, for: .normal)
        forgotPasswordBtn.setTitle(AppStrings.Authentication.forgotPassword, for: .normal)
        usernameTextField.setStaticText(text: AppStrings.Authentication.email)
        passwordTextField.setStaticText(text: AppStrings.Authentication.password)
        
    }
    
    private func showforgotPasswordVC() {
        let forgotPasswordVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "forgotPasswordVC") as! ForgotPasswordViewController
        self.navigationController?.pushViewController(forgotPasswordVC, animated: true)
        
    }
    
    private func toggleIsSecured() {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        passwordSecureIconView.tintColor = passwordTextField.isSecureTextEntry ? UIColor(named: AppColors.appBlack.rawValue) : UIColor(named: AppColors.appPinkishGray.rawValue)
    }
    
    private func configureTextFields() {
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.addTarget(self, action: #selector(textFieldDidChangeValue(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChangeValue(_:)), for: .editingChanged)
        usernameTextField.text = viewModel.email
        passwordTextField.text = viewModel.password
    }
    
    private func tryLogin() {
        self.view.endEditing(true)
        self.showOrbisLoader()
        viewModel.tryLogin { [weak self] (data, err) in
            if let error = err {
                self?.handleViewError(error: error)
                
            }
            else {
                if let successful = data as? Bool, successful {
                    self?.goToDashboard()
                }
                else {
                    self?.showToastMessage(message: AppErrorStrings.cannotLoginAtMoment)
                }
            }
            self?.hideOrbisLoader()
        }
    }
    
    func goToDashboard() {
        NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.userDidLogin), object: true)
        guard let viewControllers = self.navigationController?.viewControllers else {
            return
        }
        var backIndex = 2
        if viewControllers.contains(where: {$0.isKind(of: AuthOptionPickerViewController.self)}) {
            backIndex = 3
        }
        let toGoToVC = viewControllers[viewControllers.count - backIndex]
        self.navigationController?.popToViewController(toGoToVC, animated: true)
    }
    
    fileprivate func handleViewError(error: Error) {
        if let genericError = error as? GenericError {
            showToastMessage(message: genericError.errorDescription ?? AppErrorStrings.emailPasswordInvalid)
        }
        else {
            showToastMessage(message: AppErrorStrings.emailPasswordInvalid)
        }
    }
    
    @objc private func textFieldDidChangeValue(_ textField: UITextField) {
        if textField == usernameTextField {
            viewModel.email = textField.text ?? ""
        }
        else if textField == passwordTextField {
            viewModel.password = textField.text ?? ""
        }
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            tryLogin()
        }
        return true
    }
    
}

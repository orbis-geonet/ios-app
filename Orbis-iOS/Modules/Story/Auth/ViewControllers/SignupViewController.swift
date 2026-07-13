//
//  SignupViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/04/2021.
//

import UIKit
import SkyFloatingLabelTextField
import ActiveLabel

class SignupViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var nameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordTextField: PasswordSkyFloatingTextField!
    @IBOutlet weak var passwordSecureIconView: UIImageView!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var tosLabel: ActiveLabel!
    
    @IBAction func passwordHideUnhideTapped(_ sender: Any) {
        toggleIsSecured()
    }
    
    @IBAction func registerTapped(_ sender: Any) {
        trySignup()
    }
    
    var viewModel: SignupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        initializeTextFields()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        nameTextField.setStaticText(text: AppStrings.Authentication.name)
        emailTextField.setStaticText(text: AppStrings.Authentication.email)
        passwordTextField.setStaticText(text: AppStrings.Authentication.password)
        registerBtn.setTitle(AppStrings.Authentication.register, for: .normal)
    }
    
    private func toggleIsSecured() {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        passwordSecureIconView.tintColor = passwordTextField.isSecureTextEntry ? UIColor(named: AppColors.appBlack.rawValue) : UIColor(named: AppColors.appPinkishGray.rawValue)
    }
    
    private func configureTextFields() {
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        nameTextField.addTarget(self, action: #selector(textFieldDidChangeValue(_:)), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldDidChangeValue(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChangeValue(_:)), for: .editingChanged)
        
        let customType = ActiveType.custom(pattern: "\\s\(AppStrings.Settings.tos.lowercased())\\b")
        tosLabel.enabledTypes = [customType]
        tosLabel.text = AppStrings.Authentication.registrationTOSMessagePretext + "\(AppStrings.Settings.tos.lowercased())"
        tosLabel.customColor[customType] = UIColor(named: AppColors.appBlue.rawValue)
        tosLabel.customSelectedColor[customType] = UIColor(named: AppColors.appBlue.rawValue)
        tosLabel.handleCustomTap(for: customType) { [weak self] element in
            self?.tryOpenLink(urlString: AppFirebaseConfigManager.shared.orbisTOSlink)
        }
    }
    
    func tryOpenLink(urlString: String) {
        let application = UIApplication.shared
        application.open(URL(string: urlString)!, options: [:]) { (success) in
            if success {
                return
            }
        }
    }
    
    private func initializeTextFields() {
        nameTextField.text = ""
        emailTextField.text = ""
        passwordTextField.text = ""
        viewModel = SignupViewModel()
    }
    
    @objc private func textFieldDidChangeValue(_ textField: UITextField) {
        if textField == nameTextField {
            viewModel.fullName = textField.text ?? ""
        }
        else if textField == emailTextField {
            viewModel.email = textField.text ?? ""
        }
        else if textField == passwordTextField {
            viewModel.password = textField.text ?? ""
        }
    }
    
    private func trySignup() {
        self.view.endEditing(true)
        self.showOrbisLoader()
        viewModel.tryCreateUser() { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.initializeTextFields()
                self?.showToastMessage(message: AppStrings.Authentication.accountCreatedSuccessful)
                self?.goToDashboard()
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
}


extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
        }
        else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            trySignup()
        }
        return true
    }
}

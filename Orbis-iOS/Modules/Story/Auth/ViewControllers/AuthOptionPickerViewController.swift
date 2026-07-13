//
//  AuthOptionPickerViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/04/2021.
//

import UIKit

class AuthOptionPickerViewController: OrbisLocalizableViewController {
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var signupBtn: UIButton!
    @IBOutlet weak var signinBtn: UIButton!
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func signupTapped(_ sender: Any) {
        gotoAuthenticationView(withSelectionIndex: 1)
    }
    @IBAction func LoginTapped(_ sender: Any) {
        gotoAuthenticationView(withSelectionIndex: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
        updateMessageLabel()
    }
    
    override func updateStaticTexts() {
        headingLabel.text = AppStrings.Authentication.authOptionPickerHeading
        signupBtn.setTitle(AppStrings.Authentication.authOptionPickerSignup, for: .normal)
        signinBtn.setTitle(AppStrings.Authentication.authOptionPickerLogin, for: .normal)
    }
    
    private func updateMessageLabel() {
        let message = AppStrings.Authentication.authOptionPickerMessage
        let cadastreWord = AppStrings.Authentication.registerLowerCase
        let secondBoldWord = AppStrings.Authentication.fastAndFree
        
        let cadastreWordRange = (message as NSString).range(of: cadastreWord)
        let secondBoldWordRange = (message as NSString).range(of: secondBoldWord)
        
        let attributedString = NSMutableAttributedString(string: message, attributes: [
            NSAttributedString.Key.font : UIFont(name: "Roboto-Regular", size: CGFloat(14).relativeToIphone8Width())!,
            NSAttributedString.Key.foregroundColor : UIColor(named: AppColors.appBlack.rawValue)!.withAlphaComponent(0.5)
        ])
        attributedString.setAttributes([NSAttributedString.Key.font : UIFont(name: "Roboto-Bold", size: CGFloat(14).relativeToIphone8Width())!], range: cadastreWordRange)
        attributedString.setAttributes([NSAttributedString.Key.font : UIFont(name: "Roboto-Bold", size: CGFloat(14).relativeToIphone8Width())!], range: secondBoldWordRange)
        messageLabel.attributedText = attributedString
    }
    
    private func gotoAuthenticationView(withSelectionIndex index: Int) {
        let authView = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authMainVC") as! AuthMainViewController
        authView.defaultSelectionIndex = index
        self.navigationController?.pushViewController(authView, animated: true)
    }

}

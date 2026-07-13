//
//  AuthMainViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/04/2021.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import JWTDecode

class AuthMainViewController: OrbisLocalizableViewController {
    @IBOutlet weak var loginWithLabel: UILabel!
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func signinWithGoogleTapped(_ sender: Any) {
        tryGoogleSignin()
    }
    @IBAction func signinWithFacebookTapped(_ sender: Any) {
        tryFacebookLogin()
    }
    @IBAction func signinWithTwitterTapped(_ sender: Any) {
        tryTwitterLogin()
    }
    @IBAction func signinWithAppleTapped(_ sender: Any) {
        tryAppleSignin()
    }
    
    var defaultSelectionIndex: Int = 0
    var viewModel: SocialMediaLoginViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
        addObservers()
        viewModel = SocialMediaLoginViewModel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let authTapVC = segue.destination as? AuthMainTabViewController {
            authTapVC.defaultIndex = defaultSelectionIndex
        }
    }
    
    override func updateStaticTexts() {
        loginWithLabel.text = AppStrings.Authentication.authMainLoginWith
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(googleSignInDidComplete(_:)), name: Notification.Name(rawValue: AppNotificationKeys.googleSignInResult), object: nil)
    }
    
    private func tryAppleSignin() {
        let authorizationController = ASAuthorizationController(authorizationRequests: [viewModel.getAppleSigninRequest()])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func tryTwitterLogin() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryLoginWithTwitter() { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.gotoDashboard()
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func tryGoogleSignin() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryLoginWithGoogle(from: self)
    }
    
    private func tryFacebookLogin() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryLoginWithFacebook(fromView: self) { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.gotoDashboard()
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func tryProceedAppleLogin(withToken idToken: String, credential: ASAuthorizationAppleIDCredential) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryLoginWithApple(idTokenString: idToken, appleIdCredential: credential) {  [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.gotoDashboard()
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func gotoDashboard() {
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

    @objc private func googleSignInDidComplete(_ notification: NSNotification) {
        if let googleUser = notification.object as? GoogleUser {
            viewModel.tryLoginWithGoogle(withUser: googleUser) { [weak self] (data, err) in
                if let error = err {
                    self?.handleError(error: error)
                }
                else {
                    self?.gotoDashboard()
                }
                self?.hideOrbisLoader()
            }
        }
        else {
            self.hideOrbisLoader()
            self.showAlert(title: AppStrings.error, message: AppErrorStrings.googleSigninFailed)
            debugPrint("Google Sign-In Failed.")
        }
    }
}

extension AuthMainViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let _ = viewModel.currentNonce else {
                debugPrint("Invalid state: A login callback was received, but no login request was sent.")
                self.handleError(error: ResponseError.requestFailed)
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                debugPrint("Unable to fetch identity token")
                self.handleError(error: ResponseError.requestFailed)
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                debugPrint("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                self.handleError(error: ResponseError.requestFailed)
                return
            }
            guard let jwt = try? decode(jwt: idTokenString) else {
                debugPrint("Unable to decode jwtToken: \(appleIDToken.debugDescription)")
                self.handleError(error: ResponseError.requestFailed)
                return
            }
            var userEmail = jwt.claim(name: "email").string ?? ""
            if let email = appleIDCredential.email, !email.isEmpty {
                userEmail = email
            }
            guard !userEmail.isEmpty else {
                debugPrint("Could not get email from user")
                self.handleError(error: ValidationErrors.appleSignInEmptyEmail)
                return
            }
            self.tryProceedAppleLogin(withToken: idTokenString, credential: appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple error: \(error)")
        handleError(error: error)
    }
}

extension AuthMainViewController : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

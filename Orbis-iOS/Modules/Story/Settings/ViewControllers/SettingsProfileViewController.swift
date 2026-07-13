//
//  SettingsProfileViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit
import SDWebImage

import MessageUI

class SettingsProfileViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var proPicContainer: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var saveChangeView: UIView!
    
    @IBOutlet weak var fullNameLabel: UITextField!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    @IBOutlet weak var dobLabel: UITextField!
    @IBOutlet weak var genderLabel: UITextField!
    
    @IBOutlet weak var changePhotoLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var saveChangesBtn: UIButton!
    @IBOutlet weak var changePasswordBtn: UIButton!
    
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var rateAppBtn: UIButton!
    @IBOutlet weak var inviteFriendsBtn: UIButton!
    @IBOutlet weak var tosBtn: UIButton!
    @IBOutlet weak var privacyPolicyBtn: UIButton!
    @IBOutlet weak var deleteAccountBtn: UIButton!
    @IBOutlet weak var logoutBtn: UIButton!
    
    
    @IBAction func changePhotoTapped(_ sender: Any) {
        self.openImagePickerView()
    }
    @IBAction func dobTapped(_ sender: Any) {
        showDOBPickerView()
    }
    @IBAction func genderTapped(_ sender: Any) {
        showGenderSelectionView()
    }
    @IBAction func commentTapped(_ sender: Any) {
        openEmail(forEmail: AppFirebaseConfigManager.shared.orbisEmail)
    }
    @IBAction func rateAppTapped(_ sender: Any) {
        tryOpenLink(urlString: Applinks.appStoreLink)
    }
    @IBAction func inviteFriendsTapped(_ sender: Any) {
        performLinkShare(withLink: AppFirebaseConfigManager.shared.orbisWebsiteLink)
    }
    @IBAction func termsOfServiceTapped(_ sender: Any) {
        tryOpenLink(urlString: AppFirebaseConfigManager.shared.orbisTOSlink)
    }
    @IBAction func privacyPolicyTapped(_ sender: Any) {
        tryOpenLink(urlString: AppFirebaseConfigManager.shared.orbisPrivacyLink)
    }
    @IBAction func deleteAccountTapped(_ sender: Any) {
        showConfirmationPopupAndDelete()
    }
    @IBAction func logoutTapped(_ sender: Any) {
        trySignout()
    }
    @IBAction func saveChangesTapped(_ sender: Any) {
        tryUpdateProfile()
    }
    @IBAction func changePasswordTapped(_ sender: Any) {
        showChangePasswordView()
    }
    
    var viewModel: SettingsProfileViewModel!
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SettingsProfileViewModel(user: UserSessionManager.shared.currentUser!)
        handleViewModelActions()
        updateViewContent()
        updateStaticTexts()
        fullNameLabel.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    override func updateStaticTexts() {
        changePhotoLabel.text = AppStrings.changePhoto
        saveChangesBtn.setTitle(AppStrings.saveChanges, for: .normal)
        fullNameLabel.placeholder = AppStrings.Authentication.fullName
        emailLabel.placeholder = AppStrings.Authentication.email
        passwordLabel.placeholder = AppStrings.Authentication.password
        dobLabel.placeholder = AppStrings.Authentication.dobPlaceholder
        genderLabel.placeholder = AppStrings.Authentication.gender
        
        commentBtn.setTitle(AppStrings.Settings.comment, for: .normal)
        rateAppBtn.setTitle(AppStrings.Settings.rateApp, for: .normal)
        inviteFriendsBtn.setTitle(AppStrings.Settings.inviteFriends, for: .normal)
        tosBtn.setTitle(AppStrings.Settings.tos, for: .normal)
        privacyPolicyBtn.setTitle(AppStrings.Settings.privacyPolicy, for: .normal)
        deleteAccountBtn.setTitle(AppStrings.Settings.deleteAccount, for: .normal)
        logoutBtn.setTitle(AppStrings.Settings.logout, for: .normal)
    }
    
    @objc private func textDidChange(_ textField: UITextField) {
        if textField == fullNameLabel {
            viewModel.userFullName = textField.text ?? ""
            self.updateViewContent()
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
    
    private func openEmail(forEmail email: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            present(mail, animated: true)
        }
        else {
            self.showToastMessage(message: AppErrorStrings.emailAppNotAvailable)
        }
    }
    
    private func performLinkShare(withLink link: String) {
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [link], applicationActivities: nil)
        
        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = view
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func handleViewModelActions() {
        viewModel.onUserDetailUpdateError = {
            [weak self] error in
            self?.hideOrbisLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.handleError(error: error)
            }
        }
        viewModel.onUserDetailUpdateSuccess = {
            [weak self] in
            self?.hideOrbisLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.hideOrbisLoader()
                self?.updateViewContent()
            }
        }
    }
    
    private func setupImagePickerView() {
        config = YPImagePicker.getAppImageViewConfig()
        imagePickerController = YPImagePicker(configuration: config)
        imagePickerController.didFinishPicking { [weak self] (items, success) in
            guard let strongSelf = self else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            if let photo = items.singlePhoto {
                let img = photo.modifiedImage ?? photo.originalImage
                
                strongSelf.tryChangeUserProfilePhoto(image: img)
            }
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    private func tryChangeUserProfilePhoto(image: UIImage) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.uploadUserPicture(image: image)
    }
    
    func openImagePickerView() {
        setupImagePickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func updateViewContent() {
        fullNameLabel.text = viewModel.userFullName
        emailLabel.text = viewModel.userEmail
        passwordLabel.text = viewModel.userPassword
        dobLabel.text = viewModel.dob
        genderLabel.text = viewModel.gender
        updateChangedUI()
        versionLabel.text = ""
        updateProfilePic()
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.text = "Version\(AppEnvironmentManager.shared.environment == .staging ? "-Staging" : "") v" + version
        }
    }
    
    private func updateChangedUI() {
        saveChangeView.isHidden = !viewModel.hasDataChanged
    }
    
    private func updateProfilePic() {
        if let userSelectedImage = viewModel.userSelectedImage {
            proPicView.image = userSelectedImage
            return
        }
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.userProPicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.userProPicLink
        
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func showGenderSelectionView() {
        let actionSheetVC = UIAlertController(title: AppStrings.Authentication.selectGender, message: nil, preferredStyle: .actionSheet)
        let maleAction = UIAlertAction(title: OrbisGender.male.rawValue.capitalized, style: .default) { [weak self] action in
            self?.viewModel.gender =  OrbisGender.male.rawValue.capitalized
            self?.updateViewContent()
        }
        let femaleAction = UIAlertAction(title: OrbisGender.female.rawValue.capitalized, style: .default) { [weak self] action in
            self?.viewModel.gender =  OrbisGender.female.rawValue.capitalized
            self?.updateViewContent()
        }
        let otherAction = UIAlertAction(title: OrbisGender.other.rawValue.capitalized, style: .default) { [weak self] action in
            self?.viewModel.gender =  OrbisGender.other.rawValue.capitalized
            self?.updateViewContent()
        }
        actionSheetVC.addAction(maleAction)
        actionSheetVC.addAction(femaleAction)
        actionSheetVC.addAction(otherAction)
        self.present(actionSheetVC, animated: true, completion: nil)
    }
    
    private func showDOBPickerView() {
        RPicker.selectDate(title: AppStrings.selectDOB, cancelText: AppStrings.cancel.uppercased(), doneText: AppStrings.ok.uppercased(), datePickerMode: .date, selectedDate: viewModel.userDOB ?? Date(), minDate: nil, maxDate: nil, style: .Wheel) { [weak self] (date) in
            let dateStr = date.dateString(DateFormat.normalDateFormat.rawValue)
            self?.viewModel.dob = dateStr
            self?.updateViewContent()
        }
    }
    
    private func tryUpdateProfile() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryUpdateProfileInfo { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func trySignout() {
        UserSessionManager.shared.signout { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
                return
            }
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func tryDeleteAccount() {
        self.showOrbisLoader(disableUserInteraction: true)
        UserSessionManager.shared.tryDeleteAccount { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.trySignout()
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func showConfirmationPopupAndDelete() {
        self.showConfirmationAlert(title: AppStrings.ConfirmationPopup.accountDeletion, message: AppStrings.ConfirmationPopup.deleteAccountConfirmMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] (bool) in
            if bool {
                self?.tryDeleteAccount()
            }
        }
    }
    
    private func showChangePasswordView() {
        let changePasswordVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "changePasswordVC") as! ChangePasswordViewController
        changePasswordVC.modalPresentationStyle = .overFullScreen
        changePasswordVC.shouldAddFullOverlay = true
        changePasswordVC.shouldDismissViewOnTapOutside = false
        changePasswordVC.contentTitle = AppStrings.changePassword
        changePasswordVC.onSave = {
            [weak self] oldPass, newPass in
            self?.proceedChangePassword(oldPass: oldPass, newPass: newPass)
        }
        present(changePasswordVC, animated: true, completion: nil)
    }
    
    private func proceedChangePassword(oldPass: String, newPass: String) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryChangePassword(oldPass: oldPass, newPass: newPass) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.showToastMessage(message: AppStrings.SuccessMessages.passwordChanged)
                UserSessionManager.shared.signout(forceSignout: true) { [weak self] data, err in
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            }
            self?.hideOrbisLoader()
        }
    }
}

extension SettingsProfileViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

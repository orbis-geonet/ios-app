//
//  SettingsPreferencesViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit

class SettingsPreferencesViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var languageBtn: UIButton!
    @IBOutlet weak var pushNotificationLabel: UILabel!
    
    @IBOutlet weak var pushNotificationOnContainer: UIView!
    @IBOutlet weak var pushNotificationOnBtn: UIButton!
    @IBOutlet weak var pushNotificationOffContainer: UIView!
    @IBOutlet weak var pushNotificationOffBtn: UIButton!
    
    
    @IBAction func languageTapped(_ sender: Any) {
        showLanguageSelectorView()
    }
    @IBAction func pushNotificationOnTapped(_ sender: Any) {
        guard viewModel.isNotificationOn == false else {
            viewModel.tryShowPushNotificationPermission()
            return
        }
        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
    }
    @IBAction func pushNotificationOffTapped(_ sender: Any) {
        guard viewModel.isNotificationOn == true else {
            viewModel.tryShowPushNotificationPermission()
            return
        }
        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
    }
    
    var viewModel: SettingsPreferencesViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SettingsPreferencesViewModel()
        handleViewModelActionMethods()
        updateViewContent()
        updateStaticTexts()
        updateAppLanguage()
    }
    
    private func handleViewModelActionMethods() {
        viewModel.onPushNotificationEnableChanged = {
            [weak self] in
            self?.updateViewContent()
        }
        viewModel.onUserDetailUpdateError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.hideOrbisLoader()
        }
        viewModel.onUserDetailUpdateSuccess = {
            [weak self] in
            self?.hideOrbisLoader()
            self?.updateAppLanguage()
        }
    }
    
    override func updateStaticTexts() {
        languageLabel.text = AppStrings.Settings.language
        pushNotificationLabel.text = AppStrings.Settings.pushNotification
        pushNotificationOnBtn.setTitle(AppStrings.Settings.on, for: .normal)
        pushNotificationOffBtn.setTitle(AppStrings.Settings.off, for: .normal)
    }
    
    private func updateAppLanguage() {
        let language = viewModel.userLanguage
        if language == AppStrings.Language.deviceLanguage {
            let lang = AppLanguage(rawValue: Locale.current.languageCode ?? "") ?? .deviceLanguage
            let languageText = (lang == .deviceLanguage) ? AppLanguage.english.languageText : lang.languageText
            self.languageBtn.setTitle(languageText.capitalized, for: .normal)
        }
        else {
            self.languageBtn.setTitle(language.capitalized, for: .normal)
        }
    }
    
    private func updateViewContent() {
        if let notifAccess = viewModel.isNotificationOn {
            switch notifAccess {
            case true:
                updateSegmentUIView(deselectedViews: [pushNotificationOffContainer], deselectedButtons: [pushNotificationOffBtn], selectedView: pushNotificationOnContainer, selectedButton: pushNotificationOnBtn)
            case false:
                updateSegmentUIView(deselectedViews: [pushNotificationOnContainer], deselectedButtons: [pushNotificationOnBtn], selectedView: pushNotificationOffContainer, selectedButton: pushNotificationOffBtn)
            }
        }
        else {
            updateSegmentUIView(deselectedViews: [pushNotificationOnContainer, pushNotificationOffContainer], deselectedButtons: [pushNotificationOnBtn, pushNotificationOffBtn], selectedView: nil, selectedButton: nil)
        }
    }
    
    private func updateSegmentUIView(deselectedViews: [UIView], deselectedButtons: [UIButton], selectedView: UIView?, selectedButton: UIButton?) {
        for deselectedView in deselectedViews {
            deselectedView.backgroundColor = .white
        }
        for deselectedBtn in deselectedButtons {
            deselectedBtn.setTitleColor(UIColor(named: AppColors.appBlack.rawValue), for: .normal)
        }
        selectedView?.backgroundColor = UIColor(named: AppColors.appBlack.rawValue)
        selectedButton?.setTitleColor(.white, for: .normal)
    }
    
    private func tryChangeAppLanguage(language: String) {
        guard language != viewModel.userLanguage else { return }
        var newLanguage = AppLanguage(rawValue: language)?.rawValue ?? ""
        if language == AppStrings.Language.deviceLanguage {
            let lang = AppLanguage(rawValue: Locale.current.languageCode ?? "") ?? .deviceLanguage
            let languageCode = (lang == .deviceLanguage) ? AppLanguage.english.rawValue : lang.rawValue
            newLanguage = languageCode
        }
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.updateUserLanguage(value: newLanguage)
    }

    private func showLanguageSelectorView() {
        let languageSelectorVC = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "languageSelectorVC") as! SettingsLanguageSelectionViewController
        let selectedLanguage = UserSessionManager.shared.currentUser?.userLanguage.languageText ?? AppLanguage.deviceLanguage.languageText
        
        languageSelectorVC.viewModel = SettingsLanguageListViewModel(selectedLanguage: selectedLanguage)
        languageSelectorVC.modalPresentationStyle = .overFullScreen
        languageSelectorVC.onLanguageSelected = {
            [weak self] language in
            self?.tryChangeAppLanguage(language: language)
        }
        
        presentPanModal(languageSelectorVC)
    }
}

//
//  SettingsPreferencesViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import Foundation
import UIKit

class SettingsPreferencesViewModel {
    let detailManager = UserProfileManager()
    var user: OrbisUser? {
        return UserSessionManager.shared.currentUser
    }
    var isNotificationOn: Bool? {
        didSet {
            onPushNotificationEnableChanged?()
        }
    }
    var userLanguage: String {
        return user?.userLanguage.languageText ?? ""
    }
    
    var onPushNotificationEnableChanged: (() -> Void)?
    
    var onUserDetailUpdateError: ((Error) -> Void)?
    var onUserDetailUpdateSuccess: (() -> Void)?
    
    init() {
        isNotificationOn = false
        tryShowPushNotificationPermission()
    }
    
    func tryShowPushNotificationPermission() {
        isNotificationTurnedOn {
            [weak self] data, err in
            guard let bool = data as? Bool else {return}
            DispatchQueue.main.async {
                self?.isNotificationOn = bool
            }
        }
    }
    
    private func isNotificationTurnedOn(completion: @escaping responseBlock) {
        if #available(iOS 10.0, *) {
            let current = UNUserNotificationCenter.current()
            current.getNotificationSettings(completionHandler: { settings in
                switch settings.authorizationStatus {
                case .notDetermined:
                    guard let del = UIApplication.shared.delegate as? AppDelegate else {
                        completion(false, nil)
                        return
                    }
                    del.registerForPushNotifications()
                    completion(nil, nil)
                case .authorized, .provisional, .ephemeral:
                    completion(true, nil)
                    return
                case .denied:
                    completion(false, nil)
                    return
                @unknown default:
                    completion(false, nil)
                    return
                }
            })
        } else {
            completion(UIApplication.shared.isRegisteredForRemoteNotifications, nil)
        }
    }

    func updateUserLanguage(value: String) {
        guard let user = self.user else { return }
        let param: [String: Any] = [UserProfileDomainParameterKeys.Update.language: value]
        detailManager.updateUserData(userKey: user.userKey!, withParam: param) { [weak self] (data, err) in
            if let error = err {
                self?.onUserDetailUpdateError?(error)
                return
            }
            if let user = data as? OrbisUser {
                UserSessionManager.shared.saveUpdatedUserData(user: user) { data,err in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
                }
                self?.onUserDetailUpdateSuccess?()
            }
            else {
                self?.onUserDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
}

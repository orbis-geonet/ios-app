//
//  UserSessionManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import Foundation
import FirebaseAuth
import CoreLocation

class UserSessionManager {
    static let shared = UserSessionManager()
    var userCurrentLocation: CLLocationCoordinate2D?
    var userCurrentCountryISOCode: String?
    var isUserInBrazil: Bool {
        if (AppEnvironmentManager.shared.environment == .staging) {
            return true
        }
        return (userCurrentCountryISOCode?.lowercased() == "br") || (userCurrentCountryISOCode?.lowercased() == "bra")
    }
    
    var userNotificationCount: OrbisNotificationCount?
    
    var currentUser: OrbisUser? {
        get {
            if let usrBaseData = (UserDefaults.standard.object(forKey: AppUserDefaultKeys.sessionUser.rawValue) as? Data) {
                do {
                    let user = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(usrBaseData) as? OrbisUser
                    return user
                }
                catch {
                    return nil
                }
            }
            return nil
        }
    }
    
    var storedUserFcmToken: String? {
        get {
            return UserDefaults.standard.object(forKey: AppUserDefaultKeys.fcmToken.rawValue) as? String
        }
    }
    
    var branchPartnerKey: String? {
        return UserDefaults.standard.string(forKey: AppUserDefaultKeys.branchLinkPartnerKey.rawValue)
    }
    
    func setBranchPartnerKey(key: String) {
        UserDefaults.standard.set(key, forKey: AppUserDefaultKeys.branchLinkPartnerKey.rawValue)
    }
    
    func removeBranchPartnerKey() {
        UserDefaults.standard.removeObject(forKey: AppUserDefaultKeys.branchLinkPartnerKey.rawValue)
    }
    
    var hasOnboardingBeenShown: Bool {
        return UserDefaults.standard.bool(forKey: AppUserDefaultKeys.onboardingShown.rawValue)
    }
    
    func setOnboardingShown() {
        UserDefaults.standard.set(true, forKey: AppUserDefaultKeys.onboardingShown.rawValue)
    }
    
    var hasLoginOnboardingBeenShown: Bool {
        return UserDefaults.standard.bool(forKey: AppUserDefaultKeys.loginBoardingShown.rawValue)
    }
    
    func setLoginOnboardingShown() {
        UserDefaults.standard.set(true, forKey: AppUserDefaultKeys.loginBoardingShown.rawValue)
    }
    
    var hasNormalUserSubscriptionPopupShown: Bool {
        return UserDefaults.standard.bool(forKey: AppUserDefaultKeys.normalUserSubscriptionPopupShown.rawValue)
    }
    
    func setNormalUserSubscriptionPopupShown() {
        UserDefaults.standard.set(true, forKey: AppUserDefaultKeys.normalUserSubscriptionPopupShown.rawValue)
    }
    
    var hasGroupMainAdminSubscriptionPopupShown: Bool {
        return UserDefaults.standard.bool(forKey: AppUserDefaultKeys.groupMainAdminSubscriptionPopupShown.rawValue)
    }
    
    func setGroupMainAdminSubscriptionPopupShown() {
        UserDefaults.standard.set(true, forKey: AppUserDefaultKeys.groupMainAdminSubscriptionPopupShown.rawValue)
    }
    
    func saveUsertoDefaults(user: OrbisUser, completion: @escaping responseBlock) {
        do {
            guard self.currentUser?.userKey == user.userKey || self.currentUser == nil else {
                completion(false, nil)
                return
            }
            let storedUser = self.currentUser ?? user
            storedUser.idToken = user.idToken
            storedUser.refreshToken = user.refreshToken
            storedUser.superAdmin = user.superAdmin
            storedUser.name = user.name
            storedUser.imageName = user.imageName
            storedUser.providerImageUrl = user.providerImageUrl
            storedUser.pushNotificationsEnabled = user.pushNotificationsEnabled
            let archUser = try NSKeyedArchiver.archivedData(withRootObject: storedUser, requiringSecureCoding: false)
            UserDefaults.standard.set(archUser, forKey: AppUserDefaultKeys.sessionUser.rawValue)
            completion(true, nil)
        }
        catch {
            completion(false, nil)
            return
        }
    }
    
    func saveUpdatedUserData(user: OrbisUser, completion: @escaping responseBlock) {
        do {
            let storedUser = self.currentUser
            guard storedUser?.userKey == user.userKey else {
                completion(false, nil)
                return
            }
            user.idToken = storedUser?.idToken
            user.refreshToken = storedUser?.refreshToken
            if let storedSuperAdmin = storedUser?.superAdmin {
                user.superAdmin = storedSuperAdmin
            }
            let archUser = try NSKeyedArchiver.archivedData(withRootObject: user, requiringSecureCoding: false)
            UserDefaults.standard.set(archUser, forKey: AppUserDefaultKeys.sessionUser.rawValue)
            completion(true, nil)
        }
        catch {
            completion(false, nil)
            return
        }
    }
    
    func signout(forceSignout: Bool = false, completion: @escaping responseBlock) {
        if let fcmToken = self.storedUserFcmToken, !forceSignout {
            self.updateFirebaseToken(fcmToken: fcmToken, shouldAddToken: false) { (data, err) in
                self.performSignout(completion: completion)
            }
        }
        else {
            self.performSignout(completion: completion)
        }
    }
    
    private func performSignout(completion: @escaping responseBlock) {
        logoutFirebase { data, err in
            if let error = err {
                completion(nil, error)
                return
            }
            self.userNotificationCount = nil
            UserDefaults.standard.removeObject(forKey: AppUserDefaultKeys.sessionUser.rawValue)
            let storedOnboardingValue = self.hasOnboardingBeenShown
            let storedLoginOnboardingValue = self.hasLoginOnboardingBeenShown
            let normalUserSubscriptionPopupValue = self.hasNormalUserSubscriptionPopupShown
            let adminUserSubscriptionPopupValue = self.hasGroupMainAdminSubscriptionPopupShown
            let savedBranchLinkKey = self.branchPartnerKey
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            if storedOnboardingValue {
                self.setOnboardingShown()
            }
            if storedLoginOnboardingValue {
                self.setLoginOnboardingShown()
            }
            if normalUserSubscriptionPopupValue {
                self.setNormalUserSubscriptionPopupShown()
            }
            if adminUserSubscriptionPopupValue {
                self.setGroupMainAdminSubscriptionPopupShown()
            }
            if let key = savedBranchLinkKey {
                self.setBranchPartnerKey(key: key)
            }
            UserDefaults.standard.synchronize()
            completion(true, nil)
        }
    }
    
    func logoutFirebase(completion: @escaping responseBlock) {
        do {
            try Auth.auth().signOut()
            completion(true, nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
            completion(nil, signOutError)
        }
    }
    
    func tryDeleteAccount(completion: @escaping responseBlock) {
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        let url = GetApiAddress.profile(.me, []).url
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    static func replaceAuthorizationValueInHeader(header: [String: String]) -> [String: String] {
        var newHeader = header
        newHeader.removeValue(forKey: "Authorization")
        let accessToken = UserSessionManager.shared.currentUser?.idToken ?? ""
        newHeader["Authorization"] = "Bearer \(accessToken)"
        return newHeader
    }
    
    func addFirebaseToken(parameter: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.fcmToken, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .json)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameter, method: .put, headers: headers, isContentJSONString: true, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                let fcmToken = parameter.first!.value as! String
                UserDefaults.standard.set(fcmToken, forKey: AppUserDefaultKeys.fcmToken.rawValue)
                completion(true, nil)
            }
        })
    }
    
    func removeFirebaseToken(parameter: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.fcmToken, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .json)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameter, method: .delete, headers: headers, isContentJSONString: true, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                UserDefaults.standard.removeObject(forKey: AppUserDefaultKeys.fcmToken.rawValue)
                completion(true, nil)
            }
        })
    }
    
    func updateFirebaseToken(fcmToken: String, shouldAddToken: Bool,completion: @escaping responseBlock) {
        let param = ["fcm-token": fcmToken]
        if shouldAddToken {
            self.addFirebaseToken(parameter: param, completion: completion)
        }
        else {
            self.removeFirebaseToken(parameter: param, completion: completion)
        }
    }
}

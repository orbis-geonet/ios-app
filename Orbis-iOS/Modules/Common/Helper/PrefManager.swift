//
//  PrefManager.swift
//  Orbis-iOS
//
//  Created by Kamran on 01/11/2024.
//


import Foundation

class PrefManager {
    private let userDefaults = UserDefaults.standard
    
    private let idTokenKey = "idToken"
    private let userKey = "userKey"
    private let refreshTokenKey = "refreshToken"
    private let refreshEmailKey = "email"
    private let firstLaunchKey = "firstLaunch"
    private let isSocialLoginKey = "isSocialLogin"
    private let userNameKey = "userName"
    private let languageKey = "langKey"
    private let unitKey = "unitKey"
    private let notiKey = "notiKey"
    private let fcmKey = "fcmKey"
    private let countryNameKey = "countryName"
    private let partnerKey = "partnerKey"
    
    func saveFirstLaunch() {
        userDefaults.set(false, forKey: firstLaunchKey)
    }
    
    func isFirstLaunch() -> Bool {
        return userDefaults.bool(forKey: firstLaunchKey) || !userDefaults.contains(key: firstLaunchKey)
    }
    
    func saveIdToken(_ token: String) {
        userDefaults.set(token, forKey: idTokenKey)
    }
    
    func getIdToken() -> String? {
        return userDefaults.string(forKey: idTokenKey)
    }
    
    func saveUserName(_ name: String) {
        userDefaults.set(name, forKey: userNameKey)
    }
    
    func getUserName() -> String? {
        return userDefaults.string(forKey: userNameKey)
    }
    
    func saveUserKey(_ key: String) {
        userDefaults.set(key, forKey: userKey)
    }
    
    func getUserKey() -> String? {
        return userDefaults.string(forKey: userKey)
    }
    
    func saveRefreshToken(_ token: String) {
        userDefaults.set(token, forKey: refreshTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return userDefaults.string(forKey: refreshTokenKey)
    }
    
    func saveEmail(_ email: String) {
        userDefaults.set(email, forKey: refreshEmailKey)
    }
    
    func getRefreshEmail() -> String? {
        return userDefaults.string(forKey: refreshEmailKey)
    }
    
    func saveSocialLogin() {
        userDefaults.set(true, forKey: isSocialLoginKey)
    }
    
    func deleteSocialLogin() {
        userDefaults.set(false, forKey: isSocialLoginKey)
    }
    
    func isSocialLogin() -> Bool {
        return userDefaults.bool(forKey: isSocialLoginKey)
    }
    
    func saveLanguage(_ language: String) {
        userDefaults.set(language, forKey: languageKey)
    }
    
    func getLanguage() -> String? {
        return userDefaults.string(forKey: languageKey) ?? "dd"
    }
    
    func saveUnit(_ unit: String) {
        userDefaults.set(unit, forKey: unitKey)
    }
    
    func getUnit() -> String? {
        return userDefaults.string(forKey: unitKey) ?? "Miles"
    }
    
    func saveNotification(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: notiKey)
    }
    
    func getNotification() -> Bool {
        return userDefaults.bool(forKey: notiKey)
    }
    
    func saveFcm(_ token: String) {
        userDefaults.set(token, forKey: fcmKey)
    }
    
    func getFcm() -> String? {
        return userDefaults.string(forKey: fcmKey)
    }
    
    func saveCountryName(_ name: String) {
        userDefaults.set(name, forKey: countryNameKey)
    }
    
    func getCountryName() -> String? {
        return userDefaults.string(forKey: countryNameKey)
    }
    
    func savePartnerKey(_ key: String?) {
        userDefaults.set(key, forKey: partnerKey)
        //TODO: need to fix this
       // Constants.partnerKey = key
    }
    
    func initPartnerKey() {
        //TODO: need to fix this
        //Constants.partnerKey = userDefaults.string(forKey: partnerKey)
    }
}

// Helper extension to check if a key exists
extension UserDefaults {
    func contains(key: String) -> Bool {
        return self.object(forKey: key) != nil
    }
}

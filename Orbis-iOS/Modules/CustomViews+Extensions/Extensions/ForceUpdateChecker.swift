//
//  ForceUpdateChecker.swift
//  Orbis-iOS
//
//  Created by Zohaib on 23/03/2025.
//

import Foundation
import FirebaseRemoteConfig

class ForceUpdateChecker {
    
    enum UpdateStatus {
        case shouldUpdate
        case noUpdate
    }
    
    static let TAG = "ForceUpdateChecker"
    static let FORCE_UPDATE_STORE_URL = "force_update_store_url"
    static let FORCE_UPDATE_CURRENT_VERSION = "force_update_current_version"
    static let IS_FORCE_UPDATE_REQUIRED = "is_force_update_required"
    
    func getAppVersion() -> String {
        let version = "\(Bundle.appVersionBundle)(\(Bundle.appBuildBundle))"
        print("version is \(version)")
        return version
    }
    
//    func check() -> UpdateStatus {
//        let remoteConfig = RemoteConfig.remoteConfig()
//        let forceRequired = remoteConfig[ForceUpdateChecker.IS_FORCE_UPDATE_REQUIRED].boolValue
//        print("force required \(forceRequired)")
//        
//        guard let currentAppStoreVersion = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION].stringValue else {
//            return .noUpdate
//        }
//        
//        let appVersion = getAppVersion()
//        print("current app store version is from firebase \(currentAppStoreVersion) and app version is from bundle \(appVersion)")
//        
//        if(forceRequired == true){
//            guard let currentAppStoreVersion = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION].stringValue else {
//                return .noUpdate
//            }
//            
//            let appVersion = getAppVersion()
//            print("current app store version is from firebase \(currentAppStoreVersion) and app version is from bundle \(appVersion)")
//            
//            
//            if(currentAppStoreVersion > appVersion){
//                let url = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_STORE_URL].stringValue
//                if(url != nil){
//                    print("user should update")
//                    return .shouldUpdate
//                }
//            }
//        }
//        print("no update needed")
//        return .noUpdate
//    }
    
    
    func check() -> UpdateStatus {
        let remoteConfig = RemoteConfig.remoteConfig()
        let forceRequired = remoteConfig[ForceUpdateChecker.IS_FORCE_UPDATE_REQUIRED].boolValue

        let currentAppStoreVersion = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION].stringValue
        let appVersion = getAppVersion()

        print("force required \(forceRequired)")
        print("current app store version is from firebase \(currentAppStoreVersion) and app version is from bundle \(appVersion)")

        if forceRequired {
            if currentAppStoreVersion > appVersion {
                let url = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_STORE_URL].stringValue

                if !url.isEmpty {
                    print("user should update")
                    return .shouldUpdate
                }
            }
        }

        print("no update needed")
        return .noUpdate
    }
    
    func setupRemoteConfig(){
        
        let remoteConfig = RemoteConfig.remoteConfig()
        
        let defaults : [String : Any] = [
            ForceUpdateChecker.IS_FORCE_UPDATE_REQUIRED : true,
            ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION : "3.3.2(2)",
            ForceUpdateChecker.FORCE_UPDATE_STORE_URL : "https://apps.apple.com/us/app/orbis-digital-tribes/id1453025529"
        ]
        
        let expirationDuration = 0
        
        remoteConfig.setDefaults(defaults as? [String : NSObject])
        
        remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) in
            if status == .success {
                remoteConfig.activate()
            } else {
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
    }
}

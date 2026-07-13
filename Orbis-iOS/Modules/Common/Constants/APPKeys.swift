//
//  APPKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation

struct APPKeys {

    // Secrets live in Config/Secrets.xcconfig (gitignored, see Secrets.example.xcconfig)
    // and reach the app through Info.plist build-setting substitution.
    private static func secret(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            fatalError("Missing \(key). Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and fill in the values.")
        }
        return value
    }

    // Backend X-Master-Key (Android BuildConfig.X_MASTER_KEY)
    static let masterKey = secret("X_MASTER_KEY")

    struct ApiKeys {
        static var googleAPIKey: String {
            switch AppEnvironmentManager.shared.environment {
            case .staging:
                return APPKeys.secret("GOOGLE_API_KEY_STAGING")
            case .production:
                return APPKeys.secret("GOOGLE_API_KEY_PRODUCTION")
            }
        }
    }
    static var googleSigninClientId: String {
        switch AppEnvironmentManager.shared.environment {
        case .staging:
            return APPKeys.googleSigninClientId_Production // TODO: change this to staging when staging firebase is UP. Also check firebase plist file
//            return APPKeys.googleSigninClientId_Staging
        case .production:
            return APPKeys.googleSigninClientId_Production
        }
    }
    private static let googleSigninClientId_Staging = "193814336040-k81u42ldo4n8e32anfltr2hgsl39u9jv.apps.googleusercontent.com"
    private static let googleSigninClientId_Production = "278754601811-ben7u7bjh21930v1ec344fcp15qkbi41.apps.googleusercontent.com"
    struct Admob {
        static let interstitialAdUnitKey = "ca-app-pub-6738139926979321/6465768906"
        static let nativeAdUnitKey = "ca-app-pub-6738139926979321/6609185230"
    }
    
    static var applePayMerchantId: String {
        switch AppEnvironmentManager.shared.environment {
        case .staging:
            return "merchant.com.orbis.orbis.staging"
        case .production:
            return "merchant.com.orbis.app"
        }
    }
}

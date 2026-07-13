//
//  AppLinks.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/08/2021.
//

import Foundation

struct Applinks {
    static var  appStoreId : String {
        switch AppEnvironmentManager.shared.environment {
        case .staging:
            return "1588863451"
        case .production:
            return "1568688079"
        }
    }
    static let orbisEmail = "orbis.invite@gmail.com"
    static let orbisWebsiteLink = "https://orbis.social/"
    static let orbisTOSlink = "https://orbis.social/tos"
    static let orbisPrivacyLink = "https://orbis.social/privacy"
    static var appStoreLink: String {
        switch AppEnvironmentManager.shared.environment {
        case .staging:
            return "itms-apps://apple.com/app/id1588863451"
        case .production:
            return "itms-apps://apple.com/app/id1568688079"
        }
    }
}

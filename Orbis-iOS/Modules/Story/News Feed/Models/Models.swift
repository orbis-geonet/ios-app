//
//  Models.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation
import UIKit

extension OrbisUsers {
    var validList: OrbisUsers {
        return self.filter({$0.userKey?.isEmpty == false})
    }
}

enum OrbisGender: String {
    case male
    case female
    case other
}

enum OrbisCurrency: String {
    case USD = "US Dollar"
    case BRL = "Brazilian Real"
}

enum OrbisPostType: String {
    case textPost = "TEXT"
    case imagePost = "IMAGE"
    case audioPost = "AUDIO"
    case checkinPost = "CHECK_IN"
    case eventPost = "EVENT"
    case videoPost = "VIDEO"
    case unknown
}

enum OrbisInstaConnectionStatus: String {
    case connected = "CONNECTED"
    case notConnected = "NOT_CONNECTED"
}

class OrbisUserInstaConnectResponse: Codable {
    var status: String?
    var authLink: String?
    var expirationTime: String?
    
    var connectedStatus: OrbisInstaConnectionStatus {
        return OrbisInstaConnectionStatus(rawValue: status ?? "") ?? .notConnected
    }
}

enum AppLanguage: String {
    case deviceLanguage = ""
    case english = "en"
    case chinese = "zh"
    case ukranian = "uk"
    case nepali = "ne"
    case hindi = "hi"
    case indonesian = "id"
    case japanese = "ja"
    case korean = "ko"
    case malay = "ms"
    case russian = "ru"
    case thai = "th"
    case urdu = "ur"
    case vietnamise = "vi"
    case arabic = "ar"
    case swahili = "sw"
    case italian = "it"
    case turkish = "tr"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case portugues = "pt"
    case polish = "pl"
    
    var languageText: String {
        switch self {
        case .english:
            return AppStrings.Language.english
        case .arabic:
            return AppStrings.Language.arabic
        case .german:
            return AppStrings.Language.german
        case .spanish:
            return AppStrings.Language.spanish
        case .french:
            return AppStrings.Language.french
        case .hindi:
            return AppStrings.Language.hindi
        case .indonesian:
            return AppStrings.Language.indonesian
        case .italian:
            return AppStrings.Language.italian
        case .japanese:
            return AppStrings.Language.japanese
        case .korean:
            return AppStrings.Language.korean
        case .malay:
            return AppStrings.Language.malay
        case .nepali:
            return AppStrings.Language.nepali
        case .polish:
            return AppStrings.Language.polish
        case .portugues:
            return AppStrings.Language.portugues
        case .russian:
            return AppStrings.Language.russian
        case .swahili:
            return AppStrings.Language.swahili
        case .thai:
            return AppStrings.Language.thai
        case .ukranian:
            return AppStrings.Language.ukranian
        case .urdu:
            return AppStrings.Language.urdu
        case .vietnamise:
            return AppStrings.Language.vietnamise
        case .chinese:
            return AppStrings.Language.chinese
        default:
            return AppStrings.Language.deviceLanguage
        }
    }
}

typealias OrbisUsers = [OrbisUser]

class OrbisUser: NSObject, NSCoding, Codable {
    var name: String?
    var hasStory: Bool = false
    var color: UIColor = .clear
    var userKey: String?
    var pushNotificationsEnabled: Bool?
    var superAdmin: Bool?
    var fcmToken: String?
    var email: String?
    var timestamp: String?
    var activeServerTimestamp: String?
    var providerImageUrl: String?
    var unit: String?
    var imageName: String?
    var placesArePublic: Bool?
    var groupsArePublic: Bool?
    var language: String?
    var dateOfBirth: String?
    var gender: String?
    var idToken: String?
    var refreshToken: String?
    var tokenExpiryTimestamp: Date?
    var coordinates: OrbisLocationModel?
    var following: Bool?
    var totalFollowing: Int?
    var followedGroups: Int?
    var followedPlaces: Int?
    var totalFollowers: Int?
    var groupAdminCount: Int?
    var groupMemberCount: Int?
    var accountPrivate: Bool?
    var pending: Bool?
    var seen: Bool?
    var deleted: Bool?
    var blocked: Bool?
    
    var proPicLink: String? {
        return imageName ?? providerImageUrl
    }
    
    var userDisplayName: String? {
        if deleted == true {
            return AppStrings.orbisDeletedUser
        }
        return self.name
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "displayName"
        case userKey
        case pushNotificationsEnabled
        case superAdmin
        case fcmToken
        case email
        case timestamp
        case activeServerTimestamp
        case providerImageUrl
        case unit
        case placesArePublic
        case groupsArePublic
        case language
        case dateOfBirth
        case gender
        case idToken
        case refreshToken
        case imageName
        case coordinates
//        case proPicLink = "proPicLink"
//        case hasStory = "has_story"
        case following
        case totalFollowing
        case followedGroups
        case followedPlaces
        case totalFollowers
        case groupAdminCount
        case groupMemberCount
        case accountPrivate
        case pending
        case seen
        case deleted
        case blocked
    }
    
    var userLanguage: AppLanguage {
        return AppLanguage(rawValue: self.language ?? "") ?? .deviceLanguage
    }
    
//    details
    var userGroup: Int {
        return self.groupMemberCount ?? 0
    }
    var hasConnectedInstagram: Bool? = nil
    var hasFollowed: Bool {
        return following == true
    }
    
    var borderDashGap: CGFloat {
        return [0, 3, 0, 3, 3, 3].randomElement()!.toCGFloat
    }
    var borderDashWidth: CGFloat {
        return Int.random(in: 5...45).toCGFloat
    }
    
    override init() {
        self.name = ""
        self.hasStory = false
        self.color = .clear
    }
    
    init(key: String?, name: String?, proPicLink: String?) {
        self.userKey = key
        self.name = name
        self.imageName = proPicLink
    }
    
    init(name: String, proPicLink: String, hasStory: Bool, color: UIColor) {
        self.name = name
        self.imageName = proPicLink
        self.hasStory = hasStory
        self.color = color
    }
    
    // MARK:- NSCoding Methods
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name,forKey:CodingKeys.name.rawValue)
        aCoder.encode(email, forKey: CodingKeys.email.rawValue)
        aCoder.encode(userKey, forKey: CodingKeys.userKey.rawValue)
        aCoder.encode(pushNotificationsEnabled, forKey: CodingKeys.pushNotificationsEnabled.rawValue)
        aCoder.encode(superAdmin, forKey: CodingKeys.superAdmin.rawValue)
        aCoder.encode(fcmToken,forKey:CodingKeys.fcmToken.rawValue)
        aCoder.encode(timestamp,forKey:CodingKeys.timestamp.rawValue)
        aCoder.encode(activeServerTimestamp,forKey:CodingKeys.activeServerTimestamp.rawValue)
        aCoder.encode(providerImageUrl,forKey:CodingKeys.providerImageUrl.rawValue)
        aCoder.encode(unit,forKey:CodingKeys.unit.rawValue)
        aCoder.encode(placesArePublic,forKey:CodingKeys.placesArePublic.rawValue)
        aCoder.encode(language,forKey:CodingKeys.language.rawValue)
        aCoder.encode(dateOfBirth,forKey:CodingKeys.dateOfBirth.rawValue)
        aCoder.encode(gender,forKey:CodingKeys.gender.rawValue)
        aCoder.encode(idToken,forKey:CodingKeys.idToken.rawValue)
        aCoder.encode(refreshToken,forKey:CodingKeys.refreshToken.rawValue)
        aCoder.encode(imageName,forKey:CodingKeys.imageName.rawValue)
        aCoder.encode(following,forKey:CodingKeys.following.rawValue)
        aCoder.encode(totalFollowing,forKey:CodingKeys.totalFollowing.rawValue)
        aCoder.encode(followedGroups,forKey:CodingKeys.followedGroups.rawValue)
        aCoder.encode(followedPlaces,forKey:CodingKeys.followedPlaces.rawValue)
        aCoder.encode(totalFollowers,forKey:CodingKeys.totalFollowers.rawValue)
        aCoder.encode(groupAdminCount,forKey:CodingKeys.groupAdminCount.rawValue)
        aCoder.encode(groupMemberCount,forKey:CodingKeys.groupMemberCount.rawValue)
        aCoder.encode(accountPrivate,forKey:CodingKeys.accountPrivate.rawValue)
        aCoder.encode(language,forKey:CodingKeys.language.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        self.name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String ?? ""
        self.email = aDecoder.decodeObject(forKey: CodingKeys.email.rawValue) as? String
        self.userKey = aDecoder.decodeObject(forKey: CodingKeys.userKey.rawValue) as? String
        self.pushNotificationsEnabled = aDecoder.decodeObject(forKey: CodingKeys.pushNotificationsEnabled.rawValue) as? Bool
        self.superAdmin = aDecoder.decodeObject(forKey: CodingKeys.superAdmin.rawValue) as? Bool
        self.fcmToken = aDecoder.decodeObject(forKey: CodingKeys.fcmToken.rawValue) as? String
        self.timestamp = aDecoder.decodeObject(forKey: CodingKeys.timestamp.rawValue) as? String
        self.activeServerTimestamp = aDecoder.decodeObject(forKey: CodingKeys.activeServerTimestamp.rawValue) as? String
        self.providerImageUrl = aDecoder.decodeObject(forKey: CodingKeys.providerImageUrl.rawValue) as? String
        self.unit = aDecoder.decodeObject(forKey: CodingKeys.unit.rawValue) as? String
        self.placesArePublic = aDecoder.decodeObject(forKey: CodingKeys.placesArePublic.rawValue) as? Bool
        self.language = aDecoder.decodeObject(forKey: CodingKeys.language.rawValue) as? String
        self.dateOfBirth = aDecoder.decodeObject(forKey: CodingKeys.dateOfBirth.rawValue) as? String
        self.gender = aDecoder.decodeObject(forKey: CodingKeys.gender.rawValue) as? String
        self.idToken = aDecoder.decodeObject(forKey: CodingKeys.idToken.rawValue) as? String
        self.refreshToken = aDecoder.decodeObject(forKey: CodingKeys.refreshToken.rawValue) as? String
        self.imageName = aDecoder.decodeObject(forKey: CodingKeys.imageName.rawValue) as? String
        self.following = aDecoder.decodeObject(forKey: CodingKeys.following.rawValue) as? Bool
        self.totalFollowing = aDecoder.decodeObject(forKey: CodingKeys.totalFollowing.rawValue) as? Int
        self.followedGroups = aDecoder.decodeObject(forKey: CodingKeys.followedGroups.rawValue) as? Int
        self.followedPlaces = aDecoder.decodeObject(forKey: CodingKeys.followedPlaces.rawValue) as? Int
        self.totalFollowers = aDecoder.decodeObject(forKey: CodingKeys.totalFollowers.rawValue) as? Int
        self.groupAdminCount = aDecoder.decodeObject(forKey: CodingKeys.groupAdminCount.rawValue) as? Int
        self.groupMemberCount = aDecoder.decodeObject(forKey: CodingKeys.groupMemberCount.rawValue) as? Int
        self.accountPrivate = aDecoder.decodeObject(forKey: CodingKeys.accountPrivate.rawValue) as? Bool
        self.language = aDecoder.decodeObject(forKey: CodingKeys.language.rawValue) as? String
    }
    
    func updateUserFollowers(isIncrement: Bool) {
        if let userFollowers = self.totalFollowers {
            var val = isIncrement ? (userFollowers + 1) : (userFollowers - 1)
            val = val > 0 ? val : 0
            self.totalFollowers = val
        }
    }
}

extension OrbisUser {
    static func copyFrom(user: OrbisUser) -> OrbisUser {
        let copyUser = OrbisUser(key: user.userKey, name: user.name, proPicLink: user.proPicLink)
        copyUser.accountPrivate = user.accountPrivate
        copyUser.activeServerTimestamp = user.activeServerTimestamp
        copyUser.email = user.email
        copyUser.pushNotificationsEnabled = user.pushNotificationsEnabled
        copyUser.superAdmin = user.superAdmin
        copyUser.fcmToken = user.fcmToken
        copyUser.timestamp = user.timestamp
        copyUser.providerImageUrl = user.providerImageUrl
        copyUser.unit = user.unit
        copyUser.placesArePublic = user.placesArePublic
        copyUser.language = user.language
        copyUser.dateOfBirth = user.dateOfBirth
        copyUser.gender = user.gender
        copyUser.idToken = user.idToken
        copyUser.refreshToken = user.refreshToken
        copyUser.following = user.following
        copyUser.totalFollowing = user.totalFollowing
        copyUser.followedGroups = user.followedGroups
        copyUser.followedPlaces = user.followedPlaces
        copyUser.totalFollowers = user.totalFollowers
        copyUser.groupAdminCount = user.groupAdminCount
        copyUser.groupMemberCount = user.groupMemberCount
        copyUser.blocked = user.blocked
        return copyUser
    }
    
    func getChangedProfileData(fromBase user: OrbisUser) -> [String: Any] {
        var changedParam = [String: Any]()
        if let name = self.name, name != user.name {
            changedParam[UserProfileDomainParameterKeys.Update.name] = name
        }
        if let gender = self.gender, gender != user.gender {
            changedParam[UserProfileDomainParameterKeys.Update.gender] = gender
        }
        if let dob = self.dateOfBirth, dob != user.dateOfBirth {
            changedParam[UserProfileDomainParameterKeys.Update.dob] = dob
        }
        return changedParam
    }
}

extension OrbisUsers {
    
    var toPendingRequestNotifications: OrbisNotifications {
        var notifications = OrbisNotifications()
        self.forEach { user in
            let key = UUID().uuidString
            let details = "\(user.name ?? "\(AppStrings.orbisUser)") \(AppStrings.Notification.hasRequestedToFollow)"
            let type = OrbisPushNotifType.followRequest.rawValue
            let seen = user.seen ?? false
//            let timestamp = Date().isoDateString
            let notif = OrbisNotification(notificationKey: key, title: "", details: details, type: type, seen: seen, timestamp: "", fromUser: user, toUser: UserSessionManager.shared.currentUser, group: nil, place: nil, post: nil)
            notifications.append(notif)
        }
        return notifications
    }
}

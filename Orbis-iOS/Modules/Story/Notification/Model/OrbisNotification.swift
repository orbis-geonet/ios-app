//
//  OrbisNotification.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/04/2021.
//

import Foundation

struct OrbisNotificationCount: Decodable {
    let notifications: Int?
    let pendingRequests: Int?
    
    var sum: Int {
        return (notifications ?? 0) + (pendingRequests ?? 0)
    }
}

typealias OrbisNotifications = [OrbisNotification]

struct OrbisNotification: Decodable {
    
    var notificationKey: String?
    var title: String?
    var details: String?
    var type: String?
    var seen: Bool?
    var timestamp: String?
    var fromUser: OrbisUser?
    var toUser: OrbisUser?
    var group: Group?
    var place: OrbisPlace?
    var post: OrbisFeedPost?
    
    var notifType: OrbisPushNotifType {
        return OrbisPushNotifType(rawValue: type ?? "") ?? .invalid
    }
    
    var hasUser: Bool {
        return fromUser != nil
    }
    
    var notificationReceivedDateString: String {
        return Date.fromString(string: timestamp ?? "", with: ISOCommonFormatter.shared)?.timeAgoSinceNow() ?? ""
    }
    
    var boldTexts: [String] {
        return []
    }
}

extension OrbisNotifications {
    func getUnreadNotificationsIds() -> [String] {
        return self.filter({$0.seen == false}).map({$0.notificationKey!})
    }
    
    func getUnreadPendingNotificationIds() -> [String] {
        return self.filter({$0.seen == false}).map({$0.fromUser!.userKey!})
    }
}

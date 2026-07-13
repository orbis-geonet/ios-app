//
//  OrbisPushNotifObject.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/08/2021.
//

import Foundation

enum OrbisPushNotifType: String {
    case post = "POST"
    case checkin = "CHECK_IN"
    case message = "MESSAGE"
    case follower = "FOLLOWER"
    case followRequest = "FOLLOW_REQUEST"
    case comment = "COMMENT"
    case reportPost = "REPORT_POST"
    case reportGroup = "REPORT_GROUP"
    case reportUser = "REPORT_USER"
    case reportPlace = "REPORT_PLACE"
    case invalid = "orbisPN_invalid"
}

typealias OrbisPushNotifObjects = [OrbisPushNotifObject]

class OrbisPushNotifObject: Codable {
    var id: String?
    var senderKey: String?
    var type: String?
    var contentKey: String?
    
    var notifType: OrbisPushNotifType {
        return OrbisPushNotifType(rawValue: type ?? "") ?? .invalid
    }
    
    var isValid: Bool {
        return id != nil && type != nil && contentKey != nil  && senderKey != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "gcm.message_id"
        case senderKey = "fromUserKey"
        case type
        case contentKey
    }
    
    init() {
        id = nil
        senderKey = nil
        type = nil
        contentKey = nil
    }
    
    static func initFrom(userInfo: [String: Any]) -> OrbisPushNotifObject? {
        guard let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) else {
            return nil
        }
        guard let notifObj = try? JSONDecoder().decode(OrbisPushNotifObject.self, from: data) else {
            return nil
        }
        return notifObj
    }
}

extension OrbisPushNotifObjects {
    
    mutating func excludingInvalidData() -> OrbisPushNotifObjects {
        return self.filter({$0.isValid})
    }
}

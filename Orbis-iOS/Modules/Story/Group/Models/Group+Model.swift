//
//  Group+Model.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit

class OrbisLocationModel: Codable {
    var longitude: Double?
    var latitude: Double?
}
extension OrbisLocationModel {
    func toCoordinates() -> Coordinates {
        return Coordinates(latitude: self.latitude, longitude: self.longitude)
    }
}

enum GroupRankingIndicator: String {
    case FIRE
    case RISING
    case LEVEL
    case FALLING
    case UNKNOWN
    
    var icon: UIImage {
        switch self {
        case .FALLING:
            return #imageLiteral(resourceName: "group-decrease-ic")
        case .FIRE:
            return #imageLiteral(resourceName: "group-fire-ic")
        case .LEVEL:
            return #imageLiteral(resourceName: "group-constant-ic")
        case .RISING:
            return #imageLiteral(resourceName: "group-increase-ic")
        case .UNKNOWN:
            return UIImage()
        }
    }
}

typealias Groups = [Group]

class Group: Codable {
    var groupKey: String?
    var name: String?
    var imageName: String?
    var location: OrbisLocationModel?
    var description: String?
    var colorIndex: Int?
    var solidColorHex: String?
    var strokeColorHex: String?
    var timestamp: String?
    var os: String?
    var validCheckins: Int?
    var placesCount: Int?
    var baseColor: UIColor = .clear
    var indicatorIconName: String = ""
    var percentage: Double?
    var adminsCount: Int?
    var followersCount: Int?
    var membersCount: Int?
    var isFollower: Bool?
    var isMember: Bool?
    var isAdmin: Bool?
    var rankDiffType: String?
    var isStoriesHidden: Bool?
    var isMainAdmin: Bool?
    var hasSubscription: Bool?
    var hasStripeAccount: Bool?
    var isSubscriptionActivate: Bool?
    var isSubscriber: Bool?
    
    var strokeColorHexString: String? {
        return strokeColorHex ?? solidColorHex
    }
    
    var indicatorIcon: UIImage? {
        if let rankDiffType = self.rankDiffType {
            return (GroupRankingIndicator(rawValue: rankDiffType.uppercased()) ?? .UNKNOWN).icon
        }
        if indicatorIconName.isEmpty { return nil }
        return UIImage(named: indicatorIconName)
    }
    
    enum CodingKeys: String, CodingKey {
        case groupKey
        case name
        case imageName
        case location
        case description
        case colorIndex
        case solidColorHex
        case strokeColorHex
        case timestamp
        case os
        case adminsCount
        case followersCount
        case membersCount
        case validCheckins
        case placesCount
        case percentage
        case isFollower
        case isMember
        case isAdmin
        case rankDiffType
        case isStoriesHidden
        case isMainAdmin
        case hasSubscription
        case hasStripeAccount
        case isSubscriptionActivate
        case isSubscriber
//        case indicatorIconName = "indicator_icon_name"
//        case description = "description"
//        case places = "places"
//        case members = "members"
    }
    
    var borderDashGap: CGFloat {
        return [0, 3, 0, 3, 3, 3].randomElement()!.toCGFloat
    }
    var borderDashWidth: CGFloat {
        return Int.random(in: 5...45).toCGFloat
    }
    
    var groupBorderColor: UIColor {
        if let strokeColor = self.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return self.baseColor
    }
    
    init(name: String, propicLink: String, baseColor: UIColor, indicatorIconName: String, description: String, places: Int, members: Int) {
        self.name = name
        self.imageName = propicLink
        self.baseColor = baseColor
        self.indicatorIconName = indicatorIconName
        self.description = description
        self.validCheckins = places
        self.placesCount = places
    }

    init(key: String) {
        self.groupKey = key
    }
    
    static func copyFrom(group: Group) -> Group {
        let copyGroup = Group(key: group.groupKey!)
        copyGroup.adminsCount = group.adminsCount
        copyGroup.baseColor = group.baseColor
        copyGroup.colorIndex = group.colorIndex
        copyGroup.description = group.description
        copyGroup.followersCount = group.followersCount
        copyGroup.imageName = group.imageName
        copyGroup.indicatorIconName = group.indicatorIconName
        copyGroup.isAdmin = group.isAdmin
        copyGroup.isMember = group.isMember
        copyGroup.isFollower = group.isFollower
        copyGroup.location = group.location
        copyGroup.membersCount = group.membersCount
        copyGroup.name = group.name
        copyGroup.os = group.os
        copyGroup.percentage = group.percentage
        copyGroup.placesCount = group.placesCount
        copyGroup.rankDiffType = group.rankDiffType
        copyGroup.solidColorHex = group.solidColorHex
        copyGroup.strokeColorHex = group.strokeColorHex
        copyGroup.timestamp = group.timestamp
        copyGroup.validCheckins = group.validCheckins
        copyGroup.isStoriesHidden = group.isStoriesHidden
        copyGroup.isMainAdmin = group.isMainAdmin
        copyGroup.hasSubscription = group.hasSubscription
        copyGroup.hasStripeAccount = group.hasStripeAccount
        copyGroup.isSubscriptionActivate = group.isSubscriptionActivate
        copyGroup.isSubscriber = group.isSubscriber
        return copyGroup
    }
}

extension Group {
    func toGroupDetails() -> GroupDetails {
        return GroupDetails(
            groupKey: groupKey,
            name: name,
            location: location?.toCoordinates(),
            description: description,
            imageName: imageName,
            imageLink: nil, // Add default or computed value
            colorIndex: colorIndex,
            solidColorHex: solidColorHex,
            strokeColorHex: strokeColorHex,
            timestamp: timestamp,
            placesCount: placesCount,
            rank: nil, // Add default value
            rankDiff: nil, // Add default value
            rankDiffType: rankDiffType,
            deleted: nil, // Add default value
            shareLink: nil, // Add default value
            fullShareLink: nil, // Add default value
            slug: nil, // Add default value
            adminsCount: adminsCount,
            followersCount: followersCount,
            membersCount: membersCount,
            isAdmin: isAdmin,
            isMember: isMember,
            isFollower: isFollower,
            validCheckins: validCheckins,
            percentage: percentage,
            isMainAdmin: isMainAdmin,
            hasSubscription: hasSubscription,
            isSubscriptionActivate: isSubscriptionActivate,
            isSubscriber: isSubscriber,
            isBlockedByUser: nil, // Add default value
            baseColor: baseColor
        )
    }
}

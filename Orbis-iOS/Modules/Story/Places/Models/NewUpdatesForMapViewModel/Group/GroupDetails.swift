//
//  GroupDetails.swift
//  Orbis-iOS
//
//  Created by Kamran on 29/10/2024.
//

import UIKit
import Foundation

struct GroupDetails: Codable, Hashable {
    let groupKey: String?
    let name: String?
    let location: Coordinates?
    let description: String?
    var imageName: String?
    var imageLink: String?
    let colorIndex: Int?
    let solidColorHex: String?
    let strokeColorHex: String?
    let timestamp: String?
    let placesCount: Int?
    let rank: Int?
    let rankDiff: Int?
    let rankDiffType: String?
    let deleted: Bool?
    let shareLink: String?
    let fullShareLink: String?
    let slug: String?
    let adminsCount: Int?
    let followersCount: Int?
    var membersCount: Int?
    let isAdmin: Bool?
    var isMember: Bool?
    var isFollower: Bool?
    let validCheckins: Int?
    let percentage: Double?
    var isMainAdmin: Bool?
    var hasSubscription: Bool?
    var isSubscriptionActivate: Bool?
    var isSubscriber: Bool?
    var isBlockedByUser: Bool?
    
    var baseColor: UIColor = .clear
    
    private enum CodingKeys: String, CodingKey {
            case groupKey, name, location, description, imageName, imageLink, colorIndex, solidColorHex, strokeColorHex, timestamp, placesCount, rank, rankDiff, rankDiffType, deleted, shareLink, fullShareLink, slug, adminsCount, followersCount, membersCount, isAdmin, isMember, isFollower, validCheckins, percentage, isMainAdmin, hasSubscription, isSubscriptionActivate, isSubscriber, isBlockedByUser
            // Exclude `baseColor` from coding
        }
    
}

// Helper extensions for JSON serialization
extension Encodable {
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}


extension GroupDetails {
    func toEntity(fromCity: String, fromLoggedInUser: Bool) -> GroupEntity {
        let entity = GroupEntity()
        entity.groupKey = groupKey ?? ""
        entity.name = name ?? ""
        entity.location = location?.toJSONString() ?? ""
        entity.groupDescription = description ?? ""
        entity.imageName = imageName ?? ""
        entity.imageLink = imageLink ?? ""
        entity.colorIndex = colorIndex ?? 0
        entity.solidColorHex = solidColorHex ?? ""
        entity.strokeColorHex = strokeColorHex ?? ""
        entity.timestamp = timestamp ?? ""
        entity.placesCount = placesCount ?? 0
        entity.rank = rank ?? 0
        entity.rankDiff = rankDiff ?? 0
        entity.rankDiffType = rankDiffType ?? ""
        entity.deleted = deleted ?? false
        entity.shareLink = shareLink ?? ""
        entity.adminsCount = adminsCount ?? 0
        entity.followersCount = followersCount ?? 0
        entity.membersCount = membersCount ?? 0
        entity.isAdmin = isAdmin ?? false
        entity.isMember = isMember ?? false
        entity.isFollower = isFollower ?? false
        entity.validCheckins = validCheckins ?? 0
        entity.percentage = percentage ?? 0.0
        entity.isMainAdmin = isMainAdmin ?? false
        entity.hasSubscription = hasSubscription ?? false
        entity.isSubscriptionActivate = isSubscriptionActivate ?? false
        entity.isSubscriber = isSubscriber ?? false
        entity.isBlockedByUser = isBlockedByUser ?? false
        entity.fromLoggedUser = fromLoggedInUser
        entity.city = fromCity
        return entity
    }
}

//MARK: Conversion to Group Object
extension GroupDetails {
    func toGroup() -> Group {
        let group = Group(key: groupKey ?? "")
        group.name = name
        group.imageName = imageName
        // Manually map Coordinates to OrbisLocationModel
        if let location = location {
            let orbisLocationModel = OrbisLocationModel()
            orbisLocationModel.latitude = location.latitude
            orbisLocationModel.longitude = location.longitude
            group.location = orbisLocationModel
        } else {
            group.location = nil
        }
        group.description = description
        group.colorIndex = colorIndex
        group.solidColorHex = solidColorHex
        group.strokeColorHex = strokeColorHex
        group.timestamp = timestamp
        group.os = nil // Set default or computed value if needed
        group.validCheckins = validCheckins
        group.placesCount = placesCount
        group.baseColor = UIColor.hexStringToUIColor(hex: solidColorHex ?? "#FFFFFF")
        group.indicatorIconName = ""
        group.percentage = percentage
        group.adminsCount = adminsCount
        group.followersCount = followersCount
        group.membersCount = membersCount
        group.isFollower = isFollower
        group.isMember = isMember
        group.isAdmin = isAdmin
        group.rankDiffType = rankDiffType
        group.isStoriesHidden = false // Add default value
        group.isMainAdmin = isMainAdmin
        group.hasSubscription = hasSubscription
        group.hasStripeAccount = nil // Add default value
        group.isSubscriptionActivate = isSubscriptionActivate
        group.isSubscriber = isSubscriber
        return group
    }
}


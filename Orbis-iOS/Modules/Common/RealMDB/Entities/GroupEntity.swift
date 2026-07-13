//
//  GroupEntity.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import RealmSwift
import Foundation

class GroupEntity: Object {
    @objc dynamic var groupKey: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var location: String = ""
    @objc dynamic var groupDescription: String = ""
    @objc dynamic var imageName: String = ""
    @objc dynamic var imageLink: String = ""
    @objc dynamic var colorIndex: Int = 0
    @objc dynamic var solidColorHex: String = ""
    @objc dynamic var strokeColorHex: String = "#FFFFFF"
    @objc dynamic var timestamp: String = ""
    @objc dynamic var placesCount: Int = 0
    @objc dynamic var rank: Int = 0
    @objc dynamic var rankDiff: Int = 0
    @objc dynamic var rankDiffType: String = ""
    @objc dynamic var deleted: Bool = false
    @objc dynamic var shareLink: String = ""
    @objc dynamic var adminsCount: Int = 0
    @objc dynamic var followersCount: Int = 0
    @objc dynamic var membersCount: Int = 0
    @objc dynamic var isAdmin: Bool = false
    @objc dynamic var isMember: Bool = false
    @objc dynamic var isFollower: Bool = false
    @objc dynamic var validCheckins: Int = 0
    @objc dynamic var percentage: Double = 100.0
    @objc dynamic var isMainAdmin: Bool = false
    @objc dynamic var hasSubscription: Bool = false
    @objc dynamic var isSubscriptionActivate: Bool = false
    @objc dynamic var isSubscriber: Bool = false
    @objc dynamic var isBlockedByUser: Bool = false
    @objc dynamic var fromLoggedUser: Bool = false
    @objc dynamic var city: String = ""

    override static func primaryKey() -> String? {
        return "groupKey"
    }
}

extension GroupEntity {
    func toDomain() -> GroupDetails {
        let coordinates: Coordinates = {
            do {
                let data = location.data(using: .utf8) ?? Data()
                let coordinates = try JSONDecoder().decode(Coordinates.self, from: data)
                return coordinates
            } catch {
                print("Failed to decode Coordinates: \(error)")
                return Coordinates(latitude: 0.0, longitude: 0.0) // Default values
            }
        }()

        return GroupDetails(
            groupKey: groupKey,
            name: name,
            location: coordinates,
            description: groupDescription,
            imageName: imageName,
            imageLink: imageLink,
            colorIndex: colorIndex,
            solidColorHex: solidColorHex,
            strokeColorHex: strokeColorHex,
            timestamp: timestamp,
            placesCount: placesCount,
            rank: rank,
            rankDiff: rankDiff,
            rankDiffType: rankDiffType,
            deleted: deleted,
            shareLink: shareLink,
            fullShareLink: nil,
            slug: nil,
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
            isBlockedByUser: isBlockedByUser
        )
    }
}

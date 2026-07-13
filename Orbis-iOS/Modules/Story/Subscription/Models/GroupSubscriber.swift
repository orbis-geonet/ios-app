//
//  GroupSubscriber.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 22/08/2023.
//

import Foundation

typealias GroupSubscribers = [GroupSubscriber]

class GroupSubscriber: Codable {
    var name: String?
    var userKey: String?
    var superAdmin: Bool?
    var email: String?
    var providerImageUrl: String?
    var imageName: String?
    var dateOfBirth: String?
    var gender: String?
    var coordinates: OrbisLocationModel?
    var following: Bool?
    var totalFollowing: Int?
    var followedGroups: Int?
    var followedPlaces: Int?
    var totalFollowers: Int?
    var groupAdminCount: Int?
    var groupMemberCount: Int?
    var accountPrivate: Bool?
    var deleted: Bool?
    var blocked: Bool?
    var codes: [String]?
    
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
        case superAdmin
        case email
        case providerImageUrl
        case dateOfBirth
        case gender
        case imageName
        case coordinates
        case following
        case totalFollowing
        case followedGroups
        case followedPlaces
        case totalFollowers
        case groupAdminCount
        case groupMemberCount
        case accountPrivate
        case deleted
        case blocked
        case codes
    }
    
    var toUser: OrbisUser {
        let copyUser = OrbisUser(key: self.userKey, name: self.name, proPicLink: self.proPicLink)
        copyUser.accountPrivate = self.accountPrivate
        copyUser.email = self.email
        copyUser.superAdmin = self.superAdmin
        copyUser.providerImageUrl = self.providerImageUrl
        copyUser.dateOfBirth = self.dateOfBirth
        copyUser.gender = self.gender
        copyUser.following = self.following
        copyUser.totalFollowing = self.totalFollowing
        copyUser.followedGroups = self.followedGroups
        copyUser.followedPlaces = self.followedPlaces
        copyUser.totalFollowers = self.totalFollowers
        copyUser.groupAdminCount = self.groupAdminCount
        copyUser.groupMemberCount = self.groupMemberCount
        copyUser.blocked = self.blocked
        return copyUser
    }
}

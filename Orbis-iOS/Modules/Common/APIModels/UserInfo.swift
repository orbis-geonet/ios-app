//
//  UserInfo.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct UserInfo: Codable {
    var coordinates: Coordinates?
    var userKey: String?
    var displayName: String
    var imageName: String?
    var dateOfBirth: String
    var gender: String
    var providerImageUrl: String
    var accountPrivate: Bool
    var seen: Bool
    var superAdmin: Bool
    var email: String?
    var language: String?
    var following: Bool
    var pending: Bool
    var blocked: Bool
    var totalFollowing: Int
    var followedGroups: Int
    var followedPlaces: Int
    var totalFollowers: Int
    var groupAdminCount: Int
    var groupMemberCount: Int
    
    enum CodingKeys: String, CodingKey {
        case coordinates
        case userKey
        case displayName
        case imageName
        case dateOfBirth
        case gender
        case providerImageUrl
        case accountPrivate
        case seen
        case superAdmin
        case email
        case language
        case following
        case pending
        case blocked
        case totalFollowing
        case followedGroups
        case followedPlaces
        case totalFollowers
        case groupAdminCount
        case groupMemberCount
    }
}

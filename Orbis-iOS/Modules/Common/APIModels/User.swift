//
//  User.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct User: Codable {
    let coordinates: Coordinates
    let userKey: String
    let displayName: String
    let imageName: String?
    let providerImageUrl: String
    let accountPrivate: Bool
    let deleted: Bool
    let seen: Bool
    let codes: [String]?
    let user: UserModel
    
    enum CodingKeys: String, CodingKey {
        case coordinates
        case userKey
        case displayName
        case imageName
        case providerImageUrl
        case accountPrivate
        case deleted
        case seen
        case codes
        case user
    }
}

struct UserModel: Codable {
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case displayName
    }
}

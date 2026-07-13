//
//  UserProfile.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct UserProfile: Codable {
    let coordinates: Coordinates
    let userKey: String
    let providerImageUrl: String
    let unit: String
    let imageName: String
    let language: String
    let dateOfBirth: String
    let displayName: String
    let gender: String
    let accountPrivate: Bool
    let shareLink: String
    let superAdmin: String
    let email: String
    let timestamp: String
    let activeServerTimestamp: String
    let idToken: String
    let refreshToken: String
    let partnerKey: String
}

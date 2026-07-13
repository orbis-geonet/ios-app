//
//  ProfileUpdateBody.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct ProfileUpdateBody: Codable {
    var displayName: String?
    var providerImageUrl: String?
    var dateOfBirth: String? = ""
    var gender: String? = ""
    var partnerKey: String? = nil //TODO: need to fix Constants.partnerKey
}

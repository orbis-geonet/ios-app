//
//  SignUpBody.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct SignUpBody: Codable {
    var displayName: String = ""
    var email: String = ""
    var password: String = ""
    var partnerKey: String? = nil //Constants.partnerKey
}

//
//  StripeAccountStatusModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/01/2023.
//

import Foundation

struct StripeAccountStatusModel: Codable {
    var status: String?
    var userKey: String?
    var businessType: String?
    var country: String?
    var fieldError: [String]?
    
    enum CodingKeys: String, CodingKey {
        case status
        case userKey
        case businessType
        case country
        case fieldError
    }
    
    var accountStatus: StripeAccountStatusValue {
        return StripeAccountStatusValue(rawValue: status ?? "") ?? .unknown
    }
}

struct StripeAccountCreateResponse: Codable {
    var stripeAccountKey: String?
    var setupAccountUrl: String?
}

struct SubscriptionCommisionInfo: Codable {
    var orbisCommission: Double?
    var stripeCommission: Double?
    var stripeAdditionFee: Double?
    var currencies: [String]?
}

struct OrbisStripeTokenModel: Codable {
    var clientSecret: String?
    var publicToken: String?
}

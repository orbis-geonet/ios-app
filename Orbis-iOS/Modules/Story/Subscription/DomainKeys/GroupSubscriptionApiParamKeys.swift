//
//  GroupSubscriptionApiParamKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/01/2023.
//

import Foundation

struct GroupSubscriptionApiParamKeys {
    struct List {
        static let groupKey = "groupKey"
        static let purchaseKey = "purchaseKey"
    }
    struct Create {
        static let subscriptionKey = "subscriptionKey"
        static let name = "name"
        static let description = "description"
        static let price = "price"
        static let originalPrice = "originalPrice"
        static let currency = "currency"
        static let benefit = "benefit"
        static let type = "type"
        static let interval = "interval"
        static let period = "period"
        static let photos = "imagesName"
    }
    struct Graph {
        static let type = "type"
    }
    struct Buy {
        static let number = "number"
    }
}

struct StripeApiParamKeys {
    struct Create {
        static let country = "country"
        static let businessType = "businessType"
    }
}

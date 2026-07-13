//
//  PlaceDomainParameterKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 24/06/2021.
//

import Foundation

struct PlaceDomainParameterKeys {
    struct Update {
        static let description = "description"
        static let imageName = "imageName"
        static let address = "address"
        static let phone = "phone"
        static let website = "website"
        static let workingHours = "workingHours"
    }
    struct Rate {
        static let placeKey = "placeKey"
        static let rate = "rate"
    }
}

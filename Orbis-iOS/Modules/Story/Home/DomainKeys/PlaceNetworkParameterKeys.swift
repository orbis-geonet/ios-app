//
//  PlaceNetworkParameterKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/05/2021.
//

import Foundation

struct PlaceNetworkParameterKeys {
    struct Fetch {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let distance = "distance"
        static let page = "page"
        static let limit = "size"
        static let name = "name"
        static let groupOwned = "ownedByGroupKey"
    }
    struct Create {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let coordinates = "coordinates"
        static let userCoordinates = "userCoordinates"
        static let type = "type"
        static let source = "source"
        static let address = "address"
        static let name = "name"
        static let description = "description"
        static let phone = "phone"
        static let groupCreatedKey = "groupCreatedKey"
    }
}

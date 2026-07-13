//
//  GroupNetworkParameterKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 28/04/2021.
//

import Foundation

struct GroupNetworkParameterKeys {
    struct Fetch {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let name = "name"
        static let listMembers = "listMembers"
        static let page = "page"
        static let size = "size"
        static let nextPage = "nextPage"
        static let timePeriod = "timePeriod"
    }
    struct Create {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let name = "name"
        static let location = "location"
        static let description = "description"
        static let imageName = "imageName"
        static let os = "os"
        static let colorIndex = "colorIndex"
        static let solidColorHex = "solidColorHex"
        static let strokeColorHex = "strokeColorHex"
    }
}

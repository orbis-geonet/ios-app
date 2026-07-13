//
//  PostParameterKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 05/05/2021.
//

import Foundation

struct PostParameterKeys {
    struct Create {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let type = "type"
        static let title = "title"
        static let details = "details"
        static let richLinkData = "richLinkData"
        static let mediaUrls = "mediaUrls"
        static let groupKey = "groupKey"
        static let placeKey = "placeKey"
        static let checkin = "checkin"
        static let coordinates = "coordinates"
        
        struct RichLinkData {
            static let canonicalUrl = "canonicalUrl"
            static let description = "description"
            static let imageUrl = "imageUrl"
            static let originalUrl = "originalUrl"
            static let title = "title"
        }
         
        static let plannedTime = "plannedTime"
        static let plannedEndTime = "plannedEndTime"
        static let address = "address"
        //Kamran parameter added to post
        static let subType = "subType"
    }
}


